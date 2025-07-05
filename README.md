# E-quip

A lightweight macOS menu bar emoji picker with global hotkey support.

## Features

- **Global Hotkey**: Quick access with `⌘⌃Space`
- **Fast Search**: Type to filter emojis by name
- **Keyboard Navigation**: Arrow keys + Enter for selection
- **Category Browsing**: Browse emojis by category
- **Skin Tone Support**: Choose from different skin tones
- **Launch at Login**: Optional auto-start
- **Menu Bar Integration**: Clean, minimal interface

## Installation

### Build from Source

build and run:
```bash
./build.sh --run
```

### Requirements

- macOS 14.0+
- Swift 6.0+

## Build Options

The included build script supports various options:

```bash
./build.sh [OPTIONS]

Options:
  -r, --run         Run the app after building
  --release         Build in release mode
  --clean           Clean build artifacts before building
  --app-bundle      Create a proper .app bundle
  -h, --help        Show help message
```

## License

MIT License
