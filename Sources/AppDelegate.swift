//
//  AppDelegate.swift
//  Portsly
//
//  Copyright © 2025 Greg Hinkle. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    let portScanner = PortScanner()
    var showSystemProcesses = UserDefaults.standard.bool(forKey: "showSystemProcesses")
    var showOnlyDevProcesses = UserDefaults.standard.bool(forKey: "showOnlyDevProcesses")
    var cachedProcesses: [ProcessInfo] = []

    private func createInfoMenuItem(title: String, value: String, font: NSFont, color: NSColor, maxLength: Int = 0) -> NSMenuItem {
        let text: String
        if maxLength > 0 && value.count > maxLength {
            // Word wrap for long values
            let words = value.components(separatedBy: " ")
            var lines: [String] = []
            var currentLine = ""

            for word in words {
                if currentLine.isEmpty {
                    currentLine = word
                } else if (currentLine + " " + word).count <= maxLength {
                    currentLine += " " + word
                } else {
                    lines.append(currentLine)
                    currentLine = word
                }
            }
            if !currentLine.isEmpty {
                lines.append(currentLine)
            }

            // Format with title on first line, indented continuation lines
            text = title + ": " + lines.joined(separator: "\n" + String(repeating: " ", count: title.count + 2))
        } else {
            text = title.isEmpty ? value : "\(title): \(value)"
        }

        let item = NSMenuItem()
        item.isEnabled = true  // Keep enabled to preserve color
        item.action = #selector(copyToClipboard(_:))
        item.target = self
        item.representedObject = value  // Store the raw value for copying
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        item.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        return item
    }

    @objc private func copyToClipboard(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {

        // Ensure we're running as an accessory app
        NSApp.setActivationPolicy(.accessory)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard statusItem != nil else {
            return
        }

        if let button = statusItem?.button {

            // Try multiple ways to load the icon
            var iconLoaded = false

            // Try loading from Resources
            if let imagePath = Bundle.main.path(forResource: "menuIconTemplate@3x", ofType: "png"),
               let image = NSImage(contentsOfFile: imagePath) {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                button.image = image
                iconLoaded = true
            }

            // Try asset catalog
            if !iconLoaded, let image = NSImage(named: "menuIconTemplate") {
                image.isTemplate = true
                button.image = image
                iconLoaded = true
            }

            // Fallback to text
            if !iconLoaded {
                button.title = "P"
            }

            button.toolTip = "Portsly - Port Manager"
            button.isHidden = false
        }

        // Create initial menu
        let menu = NSMenu()
        menu.delegate = self
        statusItem?.menu = menu
    }

    func updateMenu() {
        guard let menu = statusItem?.menu else { return }

        let startTime = Date()

        // Clear existing items
        menu.removeAllItems()
        menu.autoenablesItems = false

        let scanStart = Date()
        // Cache all processes but filter based on showSystemProcesses
        let allProcesses = portScanner.scanPorts(showSystemProcesses: true)
        cachedProcesses = allProcesses

        let processes: [ProcessInfo]
        if showOnlyDevProcesses {
            processes = allProcesses.filter { portScanner.isDevProcess($0) }
        } else if showSystemProcesses {
            processes = allProcesses
        } else {
            processes = allProcesses.filter { !portScanner.isSystemProcess($0.name) }
        }
        _ = Date().timeIntervalSince(scanStart)
        // if debugTiming { print("Portsly: Port scanning took \(scanTime)s") }

        if processes.isEmpty {
            let item = NSMenuItem(title: "No applications listening on ports", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            // Create a map of ports to processes for easier lookup
            var portToProcesses: [Int: [(name: String, pid: Int, workingDirectory: String?, fullCommand: String?)]] = [:]

            for process in processes {
                for port in process.ports {
                    if portToProcesses[port] == nil {
                        portToProcesses[port] = []
                    }
                    portToProcesses[port]?.append((name: process.name, pid: process.pid, workingDirectory: process.workingDirectory, fullCommand: process.fullCommand))
                }
            }

            // Sort ports and create menu items
            let sortedPorts = portToProcesses.keys.sorted()

            for port in sortedPorts {
                guard let processesOnPort = portToProcesses[port] else { continue }

                // Format the menu item with port on left, process name(s) on right
                let processNames = processesOnPort.map { $0.name }.joined(separator: ", ")
                let title = String(format: "%-8d %@", port, processNames)

                let portItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                // Use attributed title for monospaced font
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
                ]
                portItem.attributedTitle = NSAttributedString(string: title, attributes: attributes)

                // Set icon if we have one (use the first process's icon)
                if let firstProcess = processes.first(where: { $0.ports.contains(port) }),
                   let icon = firstProcess.icon {
                    portItem.image = icon
                } else {
                    // Create a blank icon for alignment
                    let blankIcon = NSImage(size: NSSize(width: 16, height: 16))
                    blankIcon.lockFocus()
                    NSColor.clear.set()
                    NSRect(x: 0, y: 0, width: 16, height: 16).fill()
                    blankIcon.unlockFocus()
                    portItem.image = blankIcon
                }

                // If multiple processes on same port, or user wants to see details
                if processesOnPort.count > 1 || true {  // Always show submenu for consistency
                    let submenu = NSMenu()
                    submenu.autoenablesItems = false

                    // Add "Open in Browser" at the top
                    let openItem = NSMenuItem(title: "Open in Browser", action: #selector(openInBrowser(_:)), keyEquivalent: "")
                    openItem.representedObject = port
                    openItem.target = self
                    openItem.isEnabled = true
                    submenu.addItem(openItem)

                    submenu.addItem(NSMenuItem.separator())

                    for (name, pid, workingDirectory, fullCommand) in processesOnPort {
                        submenu.addItem(createInfoMenuItem(
                            title: "PID",
                            value: String(pid),
                            font: .systemFont(ofSize: 12),
                            color: .secondaryLabelColor
                        ))

                        if let cwd = workingDirectory {
                            submenu.addItem(createInfoMenuItem(
                                title: "Directory",
                                value: cwd,
                                font: .monospacedSystemFont(ofSize: 12, weight: .regular),
                                color: .secondaryLabelColor
                            ))
                        }

                        if let cmd = fullCommand {
                            submenu.addItem(createInfoMenuItem(
                                title: "Command",
                                value: cmd,
                                font: .monospacedSystemFont(ofSize: 12, weight: .regular),
                                color: .secondaryLabelColor,
                                maxLength: 50
                            ))
                        }

                        let killItem = NSMenuItem(title: "Kill \(name)", action: #selector(killProcess(_:)), keyEquivalent: "")
                        killItem.representedObject = ["pid": pid, "force": false]
                        killItem.target = self
                        killItem.isEnabled = true
                        submenu.addItem(killItem)

                        let forceKillItem = NSMenuItem(title: "Force Quit \(name)", action: #selector(killProcess(_:)), keyEquivalent: "")
                        forceKillItem.representedObject = ["pid": pid, "force": true]
                        forceKillItem.target = self
                        forceKillItem.isEnabled = true
                        submenu.addItem(forceKillItem)

                        if processesOnPort.count > 1,
                           let last = processesOnPort.last,
                           (name != last.name || pid != last.pid) {
                            submenu.addItem(NSMenuItem.separator())
                        }
                    }

                    portItem.submenu = submenu
                }

                menu.addItem(portItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        let devToggleItem = NSMenuItem(title: "Show Only Dev Processes",
                                   action: #selector(toggleDevProcesses),
                                   keyEquivalent: "")
        devToggleItem.target = self
        devToggleItem.isEnabled = true
        devToggleItem.state = showOnlyDevProcesses ? .on : .off
        menu.addItem(devToggleItem)

        let systemToggleItem = NSMenuItem(title: "Show System Processes",
                                   action: #selector(toggleSystemProcesses),
                                   keyEquivalent: "")
        systemToggleItem.target = self
        systemToggleItem.isEnabled = true
        systemToggleItem.state = showSystemProcesses ? .on : .off
        menu.addItem(systemToggleItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Portsly", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        let totalTime = Date().timeIntervalSince(startTime)
        let totalTimeMs = totalTime * 1000
        print(String(format: "[%.0fms] Portsly: Total menu update", totalTimeMs))
    }

    @objc func killProcess(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? [String: Any],
              let pid = info["pid"] as? Int,
              let force = info["force"] as? Bool else { return }

        let alert = NSAlert()
        alert.messageText = force ? "Force Quit Process?" : "Kill Process?"
        alert.informativeText = "Are you sure you want to \(force ? "force quit" : "kill") this process (PID: \(pid))?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: force ? "Force Quit" : "Kill")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            if portScanner.killProcess(pid: pid, force: force) {
                updateMenu()
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Failed to \(force ? "force quit" : "kill") process"
                errorAlert.informativeText = "Could not \(force ? "force quit" : "kill") the process. You may need administrator privileges."
                errorAlert.alertStyle = .critical
                errorAlert.runModal()
            }
        }
    }

    @objc func toggleSystemProcesses(_ sender: NSMenuItem) {
        showSystemProcesses.toggle()
        sender.state = showSystemProcesses ? .on : .off

        // If showing system processes, turn off dev-only mode
        if showSystemProcesses {
            showOnlyDevProcesses = false
            UserDefaults.standard.set(false, forKey: "showOnlyDevProcesses")
        }

        // Save preference
        UserDefaults.standard.set(showSystemProcesses, forKey: "showSystemProcesses")

        filterAndUpdateMenu()
    }

    @objc func toggleDevProcesses(_ sender: NSMenuItem) {
        showOnlyDevProcesses.toggle()
        sender.state = showOnlyDevProcesses ? .on : .off

        // If showing only dev processes, turn off system processes
        if showOnlyDevProcesses {
            showSystemProcesses = false
            UserDefaults.standard.set(false, forKey: "showSystemProcesses")
        }

        // Save preference
        UserDefaults.standard.set(showOnlyDevProcesses, forKey: "showOnlyDevProcesses")

        filterAndUpdateMenu()
    }

    private func filterAndUpdateMenu() {
        // Use cached data for instant update
        guard let menu = statusItem?.menu else { return }

        // Filter cached processes based on settings
        let processes: [ProcessInfo]
        if showOnlyDevProcesses {
            processes = cachedProcesses.filter { portScanner.isDevProcess($0) }
        } else if showSystemProcesses {
            processes = cachedProcesses
        } else {
            processes = cachedProcesses.filter { !portScanner.isSystemProcess($0.name) }
        }

        // Update menu with cached data (super fast)
        rebuildMenuWithProcesses(menu: menu, processes: processes)
    }

    private func rebuildMenuWithProcesses(menu: NSMenu, processes: [ProcessInfo]) {
        // Clear existing items
        menu.removeAllItems()
        menu.autoenablesItems = false

        if processes.isEmpty {
            let item = NSMenuItem(title: "No applications listening on ports", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            // Create a map of ports to processes for easier lookup
            var portToProcesses: [Int: [(name: String, pid: Int, workingDirectory: String?, fullCommand: String?)]] = [:]

            for process in processes {
                for port in process.ports {
                    if portToProcesses[port] == nil {
                        portToProcesses[port] = []
                    }
                    portToProcesses[port]?.append((name: process.name, pid: process.pid, workingDirectory: process.workingDirectory, fullCommand: process.fullCommand))
                }
            }

            // Sort ports and create menu items
            let sortedPorts = portToProcesses.keys.sorted()

            for port in sortedPorts {
                guard let processesOnPort = portToProcesses[port] else { continue }

                // Format the menu item with port on left, process name(s) on right
                let processNames = processesOnPort.map { $0.name }.joined(separator: ", ")
                let title = String(format: "%-8d %@", port, processNames)

                let portItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                // Use attributed title for monospaced font
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
                ]
                portItem.attributedTitle = NSAttributedString(string: title, attributes: attributes)

                // Set icon if we have one (use the first process's icon)
                if let firstProcess = processes.first(where: { $0.ports.contains(port) }),
                   let icon = firstProcess.icon {
                    portItem.image = icon
                } else {
                    // Create a blank icon for alignment
                    let blankIcon = NSImage(size: NSSize(width: 16, height: 16))
                    blankIcon.lockFocus()
                    NSColor.clear.set()
                    NSRect(x: 0, y: 0, width: 16, height: 16).fill()
                    blankIcon.unlockFocus()
                    portItem.image = blankIcon
                }

                // If multiple processes on same port, or user wants to see details
                if processesOnPort.count > 1 || true {  // Always show submenu for consistency
                    let submenu = NSMenu()
                    submenu.autoenablesItems = false

                    // Add "Open in Browser" at the top
                    let openItem = NSMenuItem(title: "Open in Browser", action: #selector(openInBrowser(_:)), keyEquivalent: "")
                    openItem.representedObject = port
                    openItem.target = self
                    openItem.isEnabled = true
                    submenu.addItem(openItem)

                    submenu.addItem(NSMenuItem.separator())

                    for (name, pid, workingDirectory, fullCommand) in processesOnPort {
                        submenu.addItem(createInfoMenuItem(
                            title: "PID",
                            value: String(pid),
                            font: .systemFont(ofSize: 12),
                            color: .secondaryLabelColor
                        ))

                        if let cwd = workingDirectory {
                            submenu.addItem(createInfoMenuItem(
                                title: "Directory",
                                value: cwd,
                                font: .monospacedSystemFont(ofSize: 12, weight: .regular),
                                color: .secondaryLabelColor,
                                maxLength: 50
                            ))
                        }

                        if let cmd = fullCommand {
                            submenu.addItem(createInfoMenuItem(
                                title: "Command",
                                value: cmd,
                                font: .monospacedSystemFont(ofSize: 12, weight: .regular),
                                color: .secondaryLabelColor,
                                maxLength: 50
                            ))
                        }

                        let killItem = NSMenuItem(title: "Kill \(name)", action: #selector(killProcess(_:)), keyEquivalent: "")
                        killItem.representedObject = ["pid": pid, "force": false]
                        killItem.target = self
                        killItem.isEnabled = true
                        submenu.addItem(killItem)

                        let forceKillItem = NSMenuItem(title: "Force Quit \(name)", action: #selector(killProcess(_:)), keyEquivalent: "")
                        forceKillItem.representedObject = ["pid": pid, "force": true]
                        forceKillItem.target = self
                        forceKillItem.isEnabled = true
                        submenu.addItem(forceKillItem)

                        if processesOnPort.count > 1,
                           let last = processesOnPort.last,
                           (name != last.name || pid != last.pid) {
                            submenu.addItem(NSMenuItem.separator())
                        }
                    }

                    portItem.submenu = submenu
                }

                menu.addItem(portItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        let devToggleItem = NSMenuItem(title: "Show Only Dev Processes",
                                   action: #selector(toggleDevProcesses),
                                   keyEquivalent: "")
        devToggleItem.target = self
        devToggleItem.isEnabled = true
        devToggleItem.state = showOnlyDevProcesses ? .on : .off
        menu.addItem(devToggleItem)

        let systemToggleItem = NSMenuItem(title: "Show System Processes",
                                   action: #selector(toggleSystemProcesses),
                                   keyEquivalent: "")
        systemToggleItem.target = self
        systemToggleItem.isEnabled = true
        systemToggleItem.state = showSystemProcesses ? .on : .off
        menu.addItem(systemToggleItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Portsly", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
    }


    @objc func openInBrowser(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? Int else { return }

        let urlString = "http://localhost:\(port)"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        updateMenu()
    }
}
