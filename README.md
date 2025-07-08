# Emoji Ninja 🥷

Become the emoji master in any chat🤙

A performant macOS emoji picker. No fuss, just find emojis. Fast.

![Screenshot](demo/screenshot.png)

## Features

- **Fast Search**: Find your favorite emoji with ease 🔍️
- **Keyboard Navigation**: Arrow keys + Enter for selection ⌨️
- **Smart pop**: The window pops next to your cursor if you prefer to use your mouse 🖱️
- **Skin Tone Support**: Choose from different skin tones 🌈
- **Global Hotkey**: Quick access with `⌘⌃Space` 🔥🔑
- **100% Offline**

Free and open source. Forever.
## Installation

## Downloads
Pre-built application bundles can be downloaded from [GitHub Releases](https://github.com/mikkelam/emoji-ninja/releases/).

Note that the app bundles are not signed and notarised (as I'm currently not paying Apple for the privilege), so you'll need to [disable Gatekeeper](https://disable-gatekeeper.github.io) for Emoji Ninja. I apologize for this inconvenience.

### Build from Source

build and run:
```bash
./build.sh --run
```

### Requirements

- macOS 14.0+
- Swift 6.0+

# Development
This project is Xcode free 🙂‍↕️

## Build Options

The included build script supports various options:

```bash
./build.sh [OPTIONS]

Options:
  -r, --run         Run the app after building
  --release         Build in release mode
  --clean           Clean build artifacts before building
  --app-bundle      Create a proper .app bundle (default with -r )
  -h, --help        Show help message
```


## License

MIT License
