.PHONY: build check core-test lint root-test structural test verify

ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif
override REPO_ROOT := $(shell path='$(subst ','"'"',$(MAKEFILE_LIST))'; path=$$(printf '%s' "$$path" | /bin/sed 's/^ //'); directory=$$(/usr/bin/dirname -- "$$path"); CDPATH= cd -- "$$directory" && /bin/pwd -P)

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

root-test:
	cd "$(REPO_ROOT)" && scripts/test-makefile-root.sh

verify: structural test build root-test

check: verify
