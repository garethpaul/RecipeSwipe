.PHONY: lint test build verify

lint:
	ruby scripts/check-ios-source.rb

test:
	@if command -v xcodebuild >/dev/null 2>&1; then \
		xcodebuild test -workspace RecipeSwipe.xcworkspace -scheme RecipeSwipe -destination 'platform=iOS Simulator,name=iPhone 6' ; \
	else \
		echo "xcodebuild unavailable; XCTest suite not run"; \
	fi

build:
	@if command -v xcodebuild >/dev/null 2>&1; then \
		xcodebuild -workspace RecipeSwipe.xcworkspace -scheme RecipeSwipe -sdk iphonesimulator build ; \
	else \
		echo "xcodebuild unavailable; compile check not run"; \
	fi

verify: lint test build
