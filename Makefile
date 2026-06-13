.PHONY: build check contract-test lint structural test verify

lint:
	ruby scripts/check-ios-source.rb

contract-test:
	ruby scripts/test-asset-contract.rb
	ruby scripts/test-pan-state-contract.rb
	ruby scripts/test-swipe-direction-contract.rb
	ruby scripts/test-workflow-contract.rb

structural: lint contract-test

test:
	ruby scripts/test-asset-contract.rb
	ruby scripts/test-pan-state-contract.rb
	ruby scripts/test-swipe-direction-contract.rb
	ruby scripts/test-workflow-contract.rb
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

check: verify
