#!/bin/bash

# Emoji Ninja Build Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
BUILD_TYPE="debug"
RUN_AFTER_BUILD=false
CLEAN_BUILD=false
CREATE_APP_BUNDLE=true
APP_NAME="Emoji Ninja"

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -r, --run         Run the app after building"
    echo "  --release         Build in release mode"
    echo "  --clean           Clean build artifacts before building"

    echo "  -h, --help        Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--run)
            RUN_AFTER_BUILD=true
            shift
            ;;
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;

        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🚀 Emoji Ninja Build Script${NC}"
echo "Build type: $BUILD_TYPE"

# Clean if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo -e "${YELLOW}🧹 Cleaning build artifacts...${NC}"
    swift package clean
fi

# Build
echo -e "${GREEN}🔨 Building Emoji Ninja...${NC}"
if [ "$BUILD_TYPE" = "release" ]; then
    swift build -c release
else
    swift build
fi

echo -e "${GREEN}✅ Build completed successfully!${NC}"

# Run if requested
if [ "$RUN_AFTER_BUILD" = true ]; then
    echo -e "${YELLOW}🔪 Killing existing instances...${NC}"
    pkill -f $APP_NAME || true
    pkill -f ".build/debug/$APP_NAME" || true
    pkill -f ".build/release/$APP_NAME" || true
    sleep 0.5

    echo -e "${YELLOW}📱 Running app...${NC}"
fi

# Show executable path
if [ "$BUILD_TYPE" = "release" ]; then
    EXECUTABLE_PATH=".build/release/$APP_NAME"
else
    EXECUTABLE_PATH=".build/debug/$APP_NAME"
fi

# Create app bundle
echo -e "${YELLOW}📱 Creating app bundle...${NC}"

APP_DIR=".build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean previous bundle
rm -rf "$APP_DIR"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp "BuildResources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy and convert ninja.png to icns if it exists
if [ -f "BuildResources/ninja.png" ]; then
    echo -e "${YELLOW}🔍 Found ninja.png, copying${NC}"
    cp "BuildResources/ninja.png" "$RESOURCES_DIR/ninja.png"
else
    echo -e "${RED}❌ ninja.png not found${NC}"
fi

# Copy emoji data JSON file
echo -e "${YELLOW}📦 Copying emoji data...${NC}"
if [ -f "Sources/Resources/emoji_data.json" ]; then
    echo -e "${YELLOW}🔍 Found emoji_data.json, copying...${NC}"
    # Create bundle directory structure
    BUNDLE_DIR="$RESOURCES_DIR/Emoji Ninja_ninjalib.bundle"
    mkdir -p "$BUNDLE_DIR"
    cp "Sources/Resources/emoji_data.json" "$BUNDLE_DIR/"
else
    echo -e "${RED}❌ emoji_data.json not found${NC}"
    echo -e "${RED}❌ Build will fail without emoji data${NC}"
    exit 1
fi

echo -e "${GREEN}✅ App bundle created at: $APP_DIR${NC}"
echo -e "${GREEN}💡 You can now run: open $APP_DIR${NC}"

EXECUTABLE_PATH="$APP_DIR"

echo -e "${GREEN}📦 Executable built at: ${EXECUTABLE_PATH}${NC}"

# Auto-run the app bundle if requested
if [ "$RUN_AFTER_BUILD" = true ]; then
    echo -e "${GREEN}🏃 Launching Emoji Ninja with logs...${NC}"
    "$APP_DIR/Contents/MacOS/$APP_NAME"
fi

echo -e "${GREEN}💡 Tip: Use './build.sh --run' to build and run immediately${NC}"
