.PHONY: build check contract-test lint structural test verify

override REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

lint:
	cd "$(REPO_ROOT)" && ruby scripts/check-ios-source.rb

contract-test:
	cd "$(REPO_ROOT)" && ruby scripts/test-asset-contract.rb
	cd "$(REPO_ROOT)" && ruby scripts/test-pan-state-contract.rb
	cd "$(REPO_ROOT)" && ruby scripts/test-swipe-direction-contract.rb
	cd "$(REPO_ROOT)" && ruby scripts/test-workflow-contract.rb

structural: lint contract-test

test:
	cd "$(REPO_ROOT)" && ruby scripts/test-asset-contract.rb
	cd "$(REPO_ROOT)" && ruby scripts/test-pan-state-contract.rb
	cd "$(REPO_ROOT)" && ruby scripts/test-swipe-direction-contract.rb
	cd "$(REPO_ROOT)" && ruby scripts/test-workflow-contract.rb
	@cd "$(REPO_ROOT)" && if command -v xcodebuild >/dev/null 2>&1; then \
		xcodebuild test -workspace RecipeSwipe.xcworkspace -scheme RecipeSwipe -destination 'platform=iOS Simulator,name=iPhone 6' ; \
	else \
		echo "xcodebuild unavailable; XCTest suite not run"; \
	fi

build:
	@cd "$(REPO_ROOT)" && if command -v xcodebuild >/dev/null 2>&1; then \
		xcodebuild -workspace RecipeSwipe.xcworkspace -scheme RecipeSwipe -sdk iphonesimulator build ; \
	else \
		echo "xcodebuild unavailable; compile check not run"; \
	fi

verify: lint test build

check: verify
