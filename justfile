set shell := ["bash", "-euo", "pipefail", "-c"]

project := "EmojiNinja.xcodeproj"
scheme := "EmojiNinja"
config := "Debug"
release_config := "Release"
archive_path := "build/EmojiNinja.xcarchive"
dist_dir := "dist"
app_name := "Emoji Ninja.app"

default:
    @just --list

gen:
    xcodegen generate

clean:
    rm -rf build dist
    xcodebuild -project {{ project }} -scheme {{ scheme }} -configuration {{ config }} clean || true

build: gen
    xcodebuild -project {{ project }} -scheme {{ scheme }} -configuration {{ config }} build

test: gen
    xcodebuild -project {{ project }} -scheme {{ scheme }} -configuration {{ config }} test

run: build
    open "$(find ~/Library/Developer/Xcode/DerivedData -type d -name "{{ app_name }}" -path "*/Build/Products/{{ config }}/*" | head -n 1)"

archive: gen
    rm -rf {{ archive_path }}
    xcodebuild -project {{ project }} -scheme {{ scheme }} -configuration {{ release_config }} archive -archivePath {{ archive_path }}

app: archive
    @echo "{{ archive_path }}/Products/Applications/{{ app_name }}"

dist-zip: archive
    mkdir -p {{ dist_dir }}
    ditto -c -k --sequesterRsrc --keepParent "{{ archive_path }}/Products/Applications/{{ app_name }}" "{{ dist_dir }}/EmojiNinja.zip"

dist-dmg: archive
    mkdir -p {{ dist_dir }}/dmg
    rm -rf {{ dist_dir }}/dmg/*
    cp -R "{{ archive_path }}/Products/Applications/{{ app_name }}" {{ dist_dir }}/dmg/
    ln -s /Applications {{ dist_dir }}/dmg/Applications
    hdiutil create -srcfolder {{ dist_dir }}/dmg -format UDZO -volname "EmojiNinja" {{ dist_dir }}/EmojiNinja.dmg

install: archive
    rm -rf "/Applications/{{ app_name }}"
    cp -R "{{ archive_path }}/Products/Applications/{{ app_name }}" /Applications/

status:
    @echo "project: {{ project }}"
    @test -f project.yml && echo "xcodegen spec: present" || echo "xcodegen spec: missing"
    @test -d {{ project }} && echo "xcodeproj: present" || echo "xcodeproj: missing (run 'just gen')"
