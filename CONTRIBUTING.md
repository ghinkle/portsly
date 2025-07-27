# Contributing to Portsly

Thank you for your interest in contributing to Portsly! We welcome contributions from the community.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/portsly.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit your changes: `git commit -am 'Add some feature'`
7. Push to the branch: `git push origin feature/your-feature-name`
8. Submit a pull request

## Development Setup

### Prerequisites
- macOS 12.0 or later
- Xcode 14.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Building
```bash
# Generate Xcode project
xcodegen generate

# Open in Xcode
open Portsly.xcodeproj

# Build and run (⌘+R in Xcode)
```

## Code Style

- Follow Swift's [API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint rules if available
- Keep code simple and readable
- Add comments for complex logic

## Testing

- Test your changes on macOS 12.0+ 
- Ensure the app launches correctly from the menu bar
- Test all menu items and functionality
- Test with and without Docker installed
- Check memory usage and performance

## Reporting Issues

- Use the GitHub issue tracker
- Include macOS version and Xcode version
- Provide steps to reproduce
- Include any relevant error messages

## Pull Request Guidelines

- Keep PRs focused on a single feature or fix
- Update the README if needed
- Ensure all tests pass
- Add a clear description of changes

## License

By contributing, you agree that your contributions will be licensed under the MIT License.