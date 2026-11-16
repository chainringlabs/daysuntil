PROJECT      := DaysUntil.xcodeproj
SCHEME       := DaysUntil
DERIVED      := .build/xcode
PACKAGE      := Packages/DaysUntilCore
INSTALL_DIR  := /Applications
# CI overrides this with CODE_SIGNING_ALLOWED=NO; locally the project signs
# with the Apple Development certificate in the keychain.
XCODE_FLAGS  ?=
XCODEBUILD    = xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) $(XCODE_FLAGS)

.PHONY: generate build release test lint format check run install gallery icon clean

generate: ## Generate DaysUntil.xcodeproj from project.yml
	xcodegen generate --quiet

build: generate ## Debug build of the app and widget extension
	$(XCODEBUILD) -configuration Debug build

release: generate ## Release build
	$(XCODEBUILD) -configuration Release build

test: ## Unit and render tests for the Swift package
	swift test --package-path $(PACKAGE)

lint: ## Check formatting and lint rules without changing files
	swiftformat --lint .
	swiftlint lint --quiet

format: ## Rewrite files to match the formatting rules
	swiftformat .

check: lint test build ## Everything CI runs

run: build ## Build and launch the debug app
	open $(DERIVED)/Build/Products/Debug/DaysUntil.app

install: release ## Sync the release build into /Applications and launch it
	-osascript -e 'quit app "DaysUntil"'
	rsync -a --delete $(DERIVED)/Build/Products/Release/DaysUntil.app/ $(INSTALL_DIR)/DaysUntil.app/
	open $(INSTALL_DIR)/DaysUntil.app

gallery: ## Render every style and size to .build/gallery as PNGs
	DAYSUNTIL_RENDER_DIR=$(CURDIR)/.build/gallery swift test --package-path $(PACKAGE) --filter RenderTests
	open .build/gallery

icon: ## Regenerate the app icon PNGs
	swift scripts/make-icon.swift App/Assets.xcassets/AppIcon.appiconset

clean: ## Remove build products and the generated project
	git clean -fdX -- .build $(PACKAGE)/.build $(PROJECT)
