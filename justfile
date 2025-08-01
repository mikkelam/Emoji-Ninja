# Emoji Ninja Build Automation
# Replace scary bash scripts with clean, composable commands

# Configuration
app_name := "Emoji Ninja"
build_dir := ".build"
dist_dir := "dist"
version := `cat VERSION 2>/dev/null || echo "1.0.0"`


# List all available commands
default:
    @just --list

# Clean build artifacts
clean:
    swift package clean
    rm -rf {{build_dir}}/{{app_name}}.app
    rm -rf {{dist_dir}}

# Build debug version
build:
    @echo "🔨 Building debug version..."
    swift build

# Build release version
build-release:
    @echo "🔨 Building release version..."
    swift build -c release

# Build with clean first
build-clean mode="debug": clean
    @if [ "{{mode}}" = "release" ]; then just build-release; else just build; fi

# Kill any running instances
kill:
    #!/usr/bin/env bash
    echo "🔪 Killing existing instances..."
    pkill -f "{{app_name}}" || true
    pkill -f ".build/debug/{{app_name}}" || true
    pkill -f ".build/release/{{app_name}}" || true
    sleep 0.5

# Create app bundle structure
_create-bundle mode="debug":
    #!/usr/bin/env bash
    echo "📱 Creating app bundle..."

    if [ "{{mode}}" = "release" ]; then
        executable_path="{{build_dir}}/release/{{app_name}}"
    else
        executable_path="{{build_dir}}/debug/{{app_name}}"
    fi

    app_dir="{{build_dir}}/{{app_name}}.app"
    contents_dir="$app_dir/Contents"
    macos_dir="$contents_dir/MacOS"
    resources_dir="$contents_dir/Resources"

    # Create directory structure
    rm -rf "$app_dir"
    mkdir -p "$macos_dir" "$resources_dir"

    # Copy executable
    cp "$executable_path" "$macos_dir/{{app_name}}"
    chmod +x "$macos_dir/{{app_name}}"

    # Copy Info.plist
    cp "BuildResources/Info.plist" "$contents_dir/Info.plist"

    # Copy icons (optional)
    for icon in ninja.png ninja_menu.png ninja_menu@2x.png ninja_menu@3x.png; do
        if [ -f "BuildResources/$icon" ]; then
            echo "🎨 Copying $icon"
            cp "BuildResources/$icon" "$resources_dir/"
        fi
    done

    # Copy emoji data
    echo "📦 Copying emoji data..."
    if [ -f "Sources/Resources/emoji_data.json" ]; then
        bundle_dir="$resources_dir/{{app_name}}_ninjalib.bundle"
        mkdir -p "$bundle_dir"
        cp "Sources/Resources/emoji_data.json" "$bundle_dir/"
        echo "✅ Emoji data copied"
    else
        echo "❌ emoji_data.json not found - run 'just fetch-emoji' first"
        exit 1
    fi

    echo "✅ App bundle created at: $app_dir"

# Create debug app bundle
bundle: build
    just _create-bundle debug

# Create release app bundle
bundle-release: build-release
    just _create-bundle release

# Run debug version
run: bundle kill
    @echo "🏃 Launching {{app_name}}..."
    "{{build_dir}}/{{app_name}}.app/Contents/MacOS/{{app_name}}"

# Run release version
run-release: bundle-release kill
    @echo "🏃 Launching {{app_name}} (release)..."
    "{{build_dir}}/{{app_name}}.app/Contents/MacOS/{{app_name}}"

# Open app bundle in Finder
open: bundle
    open "{{build_dir}}/{{app_name}}.app"

# Fetch emoji data (if needed)
fetch-emoji:
    @echo "📥 Fetching emoji data..."
    bash "fetch_emoji_data.sh"



# Create ZIP archive for distribution
_create-zip: bundle-release
    @echo "📦 Creating ZIP archive..."
    mkdir -p {{dist_dir}}
    cd {{build_dir}} && zip -r "../{{dist_dir}}/EmojiNinja-v{{version}}-macos.zip" "{{app_name}}.app"
    @echo "✅ ZIP created: {{dist_dir}}/EmojiNinja-v{{version}}-macos.zip"

# Create DMG for distribution
_create-dmg: bundle-release
    @echo "💿 Creating DMG..."
    rm -rf "{{dist_dir}}/EmojiNinja-v{{version}}.dmg" "{{dist_dir}}/dmg_staging"
    mkdir -p "{{dist_dir}}/dmg_staging"

    # Copy app and create Applications symlink
    cp -R "{{build_dir}}/{{app_name}}.app" "{{dist_dir}}/dmg_staging/"
    ln -s /Applications "{{dist_dir}}/dmg_staging/Applications"

    # Create DMG
    hdiutil create -srcfolder "{{dist_dir}}/dmg_staging" -format UDZO -volname "EmojiNinja-v{{version}}" "{{dist_dir}}/EmojiNinja-v{{version}}.dmg"
    rm -rf "{{dist_dir}}/dmg_staging"

    @echo "✅ DMG created: {{dist_dir}}/EmojiNinja-v{{version}}.dmg"

# Create checksums for distribution files
_checksums:
    @echo "🔍 Creating checksums..."
    cd {{dist_dir}} && shasum -a 256 *.dmg *.zip 2>/dev/null > checksums.txt || echo "No files to checksum"



# Full distribution build (DMG + ZIP)
dist: _create-zip _create-dmg _checksums
    @echo "🎉 Distribution complete!"
    @echo "📦 Files in {{dist_dir}}:"
    @ls -la {{dist_dir}}/

# Create only ZIP distribution
dist-zip: _create-zip _checksums
    @echo "📦 ZIP distribution ready in {{dist_dir}}/"

# Create only DMG distribution
dist-dmg: _create-dmg _checksums
    @echo "💿 DMG distribution ready in {{dist_dir}}/"

# Development workflow - build and run quickly
dev: run

# Release workflow - clean build and test
release: run-release

# Install to /Applications
install: bundle-release
    @echo "📲 Installing {{app_name}} to /Applications..."
    @if [ -d "/Applications/{{app_name}}.app" ]; then \
        echo "🗑️ Removing existing installation..."; \
        rm -rf "/Applications/{{app_name}}.app"; \
    fi
    cp -R "{{build_dir}}/{{app_name}}.app" "/Applications/"
    @echo "✅ {{app_name}} installed to /Applications"

# Check project status
status:
    @echo "📊 Project Status:"
    @echo "Version: {{version}}"
    @echo "App name: {{app_name}}"
    @test -f Sources/Resources/emoji_data.json && echo "✅ Emoji data present" || echo "❌ Emoji data missing (run 'just fetch-emoji')"
    @test -d {{build_dir}} && echo "📁 Build directory exists" || echo "📁 No build directory"
    @test -d "{{build_dir}}/{{app_name}}.app" && echo "📱 App bundle exists" || echo "📱 No app bundle"

# Get current version
get-version:
    @echo "{{version}}"

# Aliases for convenience
alias b := build
alias br := build-release
alias r := run
alias rr := run-release
alias d := dev
alias i := install
