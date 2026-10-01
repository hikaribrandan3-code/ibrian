# iBrain — build & packaging
#
# Standard Xcode builds need no local workaround. Set USE_TOOLCHAIN_FIX=1
# only on a machine with the separate Command Line Tools workaround.

TOOLCHAIN_FIX := $(HOME)/.hikari-swiftpm-libs
ifeq ($(USE_TOOLCHAIN_FIX),1)
ifneq ($(wildcard $(TOOLCHAIN_FIX)/swiftc),)
export SWIFTPM_CUSTOM_LIBS_DIR := $(TOOLCHAIN_FIX)
export SWIFT_EXEC := $(TOOLCHAIN_FIX)/swiftc
SWIFT_OVERLAY := -vfsoverlay $(TOOLCHAIN_FIX)/mask.yaml
endif
endif

APP_NAME := IBrain
BUNDLE   := dist/iBrain.app
CONTENTS := $(BUNDLE)/Contents
BINARY   := .build/release/$(APP_NAME)

.PHONY: all build app run install icon clean dmg

all: app

build:
	swift build -c release

app: build icon
	rm -rf $(BUNDLE)
	mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources $(CONTENTS)/Resources/ollama
	cp $(BINARY) $(CONTENTS)/MacOS/$(APP_NAME)
	cp Packaging/Info.plist $(CONTENTS)/Info.plist
	printf 'APPL????' > $(CONTENTS)/PkgInfo
	cp dist/AppIcon.icns $(CONTENTS)/Resources/AppIcon.icns
	if [ -f Resources/ollama/ollama ]; then cp Resources/ollama/ollama $(CONTENTS)/Resources/ollama/; chmod +x $(CONTENTS)/Resources/ollama/ollama; fi
	codesign --force --deep --sign - $(BUNDLE)
	@echo "✓ Built $(BUNDLE)"

icon: dist/AppIcon.icns

dist/AppIcon.icns: Packaging/make-icon.swift
	mkdir -p dist
	rm -rf dist/AppIcon.iconset
	swift $(SWIFT_OVERLAY) Packaging/make-icon.swift dist/AppIcon.iconset
	iconutil -c icns dist/AppIcon.iconset -o dist/AppIcon.icns

run: app
	open $(BUNDLE)

install: app
	mkdir -p /Applications/iSuite
	rm -rf "/Applications/iSuite/iBrain.app"
	ditto $(BUNDLE) "/Applications/iSuite/iBrain.app"
	@echo "✓ Installed to /Applications/iSuite/iBrain.app"

dmg: app
	@echo "Creating DMG for distribution..."
	rm -f dist/iBrain.dmg dist/iBrain-temp.dmg
	mkdir -p dist/dmg-staging
	cp -r $(BUNDLE) dist/dmg-staging/
	ln -s /Applications dist/dmg-staging/Applications
	cp Packaging/README.txt dist/dmg-staging/README.txt
	hdiutil create -volname "iBrain" -srcfolder dist/dmg-staging -ov -format UDZO dist/iBrain-temp.dmg
	mv dist/iBrain-temp.dmg dist/iBrain.dmg
	rm -rf dist/dmg-staging
	@echo "✓ Created dist/iBrain.dmg"

clean:
	rm -rf .build dist
