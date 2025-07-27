# Portsly

A lightweight macOS menu bar app that shows which applications are listening on which ports, with a quick way to kill them.

![Portsly Menu Bar](screenshots/menubar.png)

## Features

- 📊 View all listening TCP ports at a glance
- 🔍 See which process is using each port
- 📁 View working directories of processes
- 🚀 Quick "Open in Browser" for web services
- ⚡ Kill processes with one click (with confirmation)
- 🐳 Docker container name detection
- 🎯 Smart process name enhancement (shows project names from package.json, pyproject.toml, etc.)
- 🚫 Filters out system processes by default (toggleable)

## Installation

### From Release
1. Download the latest release from the [Releases](https://github.com/ghinkle/portsly/releases) page
2. Move Portsly.app to your Applications folder
3. Launch Portsly

### Build from Source
Requirements:
- macOS 12.0+
- Xcode 14+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
# Clone the repository
git clone https://github.com/ghinkle/portsly.git
cd portsly

# Quick build
./build.sh

# Or manually:
xcodegen generate
open Portsly.xcodeproj
# Then build and run in Xcode (⌘+R)
```

## Usage

1. Click the Portsly icon in your menu bar
2. View all processes listening on TCP ports
3. Click on any port to see options:
   - **Open in Browser**: Opens `http://localhost:PORT` in your default browser
   - **Kill Process**: Sends SIGTERM to the process
   - **Force Quit**: Sends SIGKILL to the process

## Privacy & Security

Portsly requires no special permissions and runs entirely locally. It uses standard macOS commands (`lsof`, `ps`) to gather information about listening ports.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Swift and SwiftUI
- Uses XcodeGen for project generation
- Icon designed with [Your Icon Tool]