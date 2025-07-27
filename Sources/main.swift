//
//  main.swift
//  Portsly
//
//  Copyright © 2025 Greg Hinkle. All rights reserved.
//

import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

app.run()
