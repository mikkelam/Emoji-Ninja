#!/bin/bash

# Emoji Ninja Distribution Script (No Code Signing)
# This script builds and packages your macOS app for GitHub distribution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Emoji Ninja"
DIST_DIR="dist"
DMG_NAME="EmojiNinja"
VERSION=$(cat VERSION 2>/dev/null || echo "1.0.0")

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --dmg-only           Only create DMG (assumes app is already built)"
    echo "  --zip-only           Only create ZIP archive"
    echo "  --version VERSION    Set version number"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "This script creates unsigned packages for GitHub distribution."
    echo "Users will need to right-click and select 'Open' to bypass Gatekeeper."
}

# Parse command line arguments
DMG_ONLY=false
ZIP_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dmg-only)
            DMG_ONLY=true
            shift
            ;;
        --zip-only)
            ZIP_ONLY=true
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
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

echo -e "${GREEN}🚀 Emoji Ninja Distribution Script${NC}"
echo -e "${YELLOW}📝 Note: This creates unsigned packages for GitHub distribution${NC}"

# Step 1: Build the app (unless DMG_ONLY or ZIP_ONLY)
if [ "$DMG_ONLY" = false ] && [ "$ZIP_ONLY" = false ]; then
    echo -e "${BLUE}📦 Step 1: Building release version...${NC}"
    ./build.sh --release --clean
fi

APP_BUNDLE=".build/$APP_NAME.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo -e "${RED}❌ Error: App bundle not found at $APP_BUNDLE${NC}"
    echo -e "${YELLOW}💡 Run without --dmg-only or --zip-only to build first${NC}"
    exit 1
fi

# Step 2: Create distribution directory
echo -e "${BLUE}📁 Step 2: Preparing distribution...${NC}"
mkdir -p "$DIST_DIR"

# Step 3: Create ZIP archive
if [ "$DMG_ONLY" = false ]; then
    echo -e "${BLUE}📦 Step 3: Creating ZIP archive...${NC}"
    ZIP_NAME="$DMG_NAME-v$VERSION-macos"
    cd .build
    zip -r "../$DIST_DIR/$ZIP_NAME.zip" "$APP_NAME.app"
    cd ..
    echo -e "${GREEN}✅ ZIP created: $DIST_DIR/$ZIP_NAME.zip${NC}"
fi

# Step 4: Create DMG (if not ZIP_ONLY)
if [ "$ZIP_ONLY" = false ]; then
    echo -e "${BLUE}💿 Step 4: Creating DMG...${NC}"

    DMG_PATH="$DIST_DIR/$DMG_NAME-v$VERSION.dmg"
    TEMP_DMG="$DIST_DIR/temp.dmg"

    # Remove existing DMG
    rm -f "$DMG_PATH" "$TEMP_DMG"

    # Create temporary DMG
    hdiutil create -size 100m -format UDRW -volname "$DMG_NAME v$VERSION" "$TEMP_DMG"

    # Mount the DMG
    MOUNT_DIR=$(hdiutil attach "$TEMP_DMG" | grep -E '^/dev/' | awk '{print $3}')

    # Copy app to DMG
    cp -R "$APP_BUNDLE" "$MOUNT_DIR/"

    # Create Applications symlink for easy installation
    ln -s /Applications "$MOUNT_DIR/Applications"

    # Add README for users about unsigned app
    cat > "$MOUNT_DIR/README.txt" << 'EOF'
Installation Instructions:

1. Drag "Emoji Ninja.app" to the Applications folder
2. Right-click on the app in Applications and select "Open"
3. Click "Open" when macOS warns about the unsigned app
4. The app will now run normally in the future

This app is unsigned because it's distributed for free.
Your security is important - only install if you trust the source.
EOF

    # Set DMG icon if available
    if [ -f "BuildResources/ninja.png" ]; then
        echo -e "${YELLOW}🎨 Adding custom icon...${NC}"
        # Convert PNG to icns for DMG
        mkdir -p tmp.iconset
        sips -z 16 16 BuildResources/ninja.png --out tmp.iconset/icon_16x16.png 2>/dev/null || true
        sips -z 32 32 BuildResources/ninja.png --out tmp.iconset/icon_16x16@2x.png 2>/dev/null || true
        sips -z 32 32 BuildResources/ninja.png --out tmp.iconset/icon_32x32.png 2>/dev/null || true
        sips -z 64 64 BuildResources/ninja.png --out tmp.iconset/icon_32x32@2x.png 2>/dev/null || true
        sips -z 128 128 BuildResources/ninja.png --out tmp.iconset/icon_128x128.png 2>/dev/null || true
        sips -z 256 256 BuildResources/ninja.png --out tmp.iconset/icon_128x128@2x.png 2>/dev/null || true
        sips -z 256 256 BuildResources/ninja.png --out tmp.iconset/icon_256x256.png 2>/dev/null || true
        sips -z 512 512 BuildResources/ninja.png --out tmp.iconset/icon_256x256@2x.png 2>/dev/null || true
        sips -z 512 512 BuildResources/ninja.png --out tmp.iconset/icon_512x512.png 2>/dev/null || true
        sips -z 1024 1024 BuildResources/ninja.png --out tmp.iconset/icon_512x512@2x.png 2>/dev/null || true

        if iconutil -c icns tmp.iconset -o "$DIST_DIR/dmg-icon.icns" 2>/dev/null; then
            echo -e "${GREEN}✅ Custom icon created${NC}"
        fi
        rm -rf tmp.iconset
    fi

    # Unmount DMG
    hdiutil detach "$MOUNT_DIR"

    # Convert to final read-only DMG
    hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_PATH"
    rm "$TEMP_DMG"

    # Set DMG icon if we created one
    if [ -f "$DIST_DIR/dmg-icon.icns" ]; then
        sips -i "$DIST_DIR/dmg-icon.icns" 2>/dev/null || true
        if command -v DeRez >/dev/null 2>&1 && command -v Rez >/dev/null 2>&1; then
            DeRez -only icns "$DIST_DIR/dmg-icon.icns" > /tmp/tmpicns.rsrc 2>/dev/null || true
            Rez -append /tmp/tmpicns.rsrc -o "$DMG_PATH" 2>/dev/null || true
            SetFile -a C "$DMG_PATH" 2>/dev/null || true
        fi
        rm -f "$DIST_DIR/dmg-icon.icns"
    fi

    echo -e "${GREEN}✅ DMG created: $DMG_PATH${NC}"
fi

# Step 5: Create checksums
echo -e "${BLUE}🔍 Step 5: Creating checksums...${NC}"
cd "$DIST_DIR"
shasum -a 256 *.dmg *.zip 2>/dev/null > checksums.txt || echo "No files to checksum"
cd ..

# Step 6: Create release notes template
echo -e "${BLUE}📝 Step 6: Creating release notes...${NC}"
cat > "$DIST_DIR/RELEASE_NOTES.md" << EOF
# Emoji Ninja v$VERSION

## Installation

### DMG (Recommended)
1. Download \`$DMG_NAME-v$VERSION.dmg\`
2. Open the DMG file
3. Drag "Emoji Ninja.app" to Applications
4. **Important**: Right-click the app and select "Open" (required for unsigned apps)
5. Click "Open" when macOS shows the security warning

### ZIP Archive
1. Download \`$DMG_NAME-v$VERSION-macos.zip\`
2. Extract and drag to Applications
3. Right-click and "Open" to bypass security warning

## What's New
- Add your changelog here

## Requirements
- macOS 14.0 or later

## Security Note
This app is unsigned (to keep it free). macOS will show a warning on first launch.
Only install if you trust the source.

## Verification
You can verify the download integrity using the checksums in \`checksums.txt\`.
EOF

echo -e "${GREEN}🎉 Distribution package completed!${NC}"
echo -e "${GREEN}📦 Files created in $DIST_DIR/:${NC}"
ls -la "$DIST_DIR/"

echo -e "${BLUE}💡 Next steps for GitHub release:${NC}"
echo -e "1. Create a new release on GitHub"
echo -e "2. Upload the DMG and/or ZIP files"
echo -e "3. Copy content from RELEASE_NOTES.md to the release description"
echo -e "4. Include installation instructions for unsigned apps"

echo -e "${YELLOW}⚠️  Important: Users must right-click and 'Open' to bypass Gatekeeper${NC}"
echo -e "${GREEN}💡 Consider adding installation GIFs to your README${NC}"
