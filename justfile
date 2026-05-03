set shell := ["bash", "-euo", "pipefail", "-c"]

project := "EmojiNinja.xcodeproj"
scheme := "EmojiNinja"
config := "Debug"
release_config := "Release"
archive_path := "build/EmojiNinja.xcarchive"
derived_data := "build/DerivedData"
dist_dir := "dist"
app_name := "Emoji Ninja.app"
app_bin := f'{{derived_data}}/Build/Products/{{config}}/{{app_name}}/Contents/MacOS/Emoji Ninja'

default:
    @just --list

gen:
    xcodegen generate

clean:
    rm -rf build dist
    xcodebuild -project {{ project }} -scheme {{ scheme }} -configuration {{ config }} -derivedDataPath {{ derived_data }} clean || true

build: gen
    xcodebuild -project {{ project }} -scheme {{ scheme }} -configuration {{ config }} -derivedDataPath {{ derived_data }} build

test: gen
    xcodebuild -project {{ project }} -scheme {{ scheme }} -configuration {{ config }} -derivedDataPath {{ derived_data }} test

run-gui: build
    open "{{ derived_data }}/Build/Products/{{ config }}/{{ app_name }}"

dev: build
    "{{ app_bin }}"

archive: gen
    rm -rf {{ archive_path }}
    xcodebuild -project {{ project }} -scheme {{ scheme }} -configuration {{ release_config }} -derivedDataPath {{ derived_data }} archive -archivePath {{ archive_path }}

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

checksums:
    shasum -a 256 {{ dist_dir }}/*.dmg {{ dist_dir }}/*.zip > {{ dist_dir }}/checksums.txt

dist: dist-zip dist-dmg checksums

get-version:
    @cat VERSION

lint:
    swift format lint -r Sources Tests Package.swift
    swiftlint

tidy:
    swift format -i -r Sources Tests Package.swift
    swiftlint --fix

install: archive
    rm -rf "/Applications/{{ app_name }}"
    cp -R "{{ archive_path }}/Products/Applications/{{ app_name }}" /Applications/

status:
    @echo "project: {{ project }}"
    @test -f project.yml && echo "xcodegen spec: present" || echo "xcodegen spec: missing"
    @test -d {{ project }} && echo "xcodeproj: present" || echo "xcodeproj: missing (run 'just gen')"

alias run := run-gui
