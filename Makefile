.PHONY: build check core-test lint structural test verify

override REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

lint:
	cd "$(REPO_ROOT)" && ruby scripts/check-ios-source.rb

structural: lint
	cd "$(REPO_ROOT)" && ruby scripts/test-asset-contract.rb
	cd "$(REPO_ROOT)" && ruby scripts/test-swipe-state-contract.rb
	cd "$(REPO_ROOT)" && ruby scripts/test-xcode-runner-contract.rb
	cd "$(REPO_ROOT)" && ruby scripts/test-workflow-contract.rb

core-test:
	cd "$(REPO_ROOT)" && scripts/swift-test.sh

test: core-test
	cd "$(REPO_ROOT)" && scripts/xcode-test.sh

build:
	cd "$(REPO_ROOT)" && scripts/xcode-build.sh

verify: structural test build

check: verify
