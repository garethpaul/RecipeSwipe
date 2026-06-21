.PHONY: build check core-test lint root-test structural test verify

override SHELL := /bin/sh
override .SHELLFLAGS := -c
ifneq ($(strip $(MAKEFILES)),)
$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)
endif
override MAKEFILES :=
ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif
override REPO_ROOT := $(shell path='$(subst ','"'"',$(MAKEFILE_LIST))'; path=$$(printf '%s' "$$path" | /usr/bin/sed 's/^ //'); [ -f "$$path" ] || exit 1; directory=$$(/usr/bin/dirname -- "$$path"); CDPATH= cd -- "$$directory" && /bin/pwd -P)
export REPO_ROOT
ifeq ($(strip $(REPO_ROOT)),)
$(error repository Makefile path could not be resolved)
endif

lint:
	cd "$$REPO_ROOT" && ruby scripts/check-ios-source.rb

structural: lint
	cd "$$REPO_ROOT" && ruby scripts/test-asset-contract.rb
	cd "$$REPO_ROOT" && ruby scripts/test-swipe-state-contract.rb
	cd "$$REPO_ROOT" && ruby scripts/test-xcode-runner-contract.rb
	cd "$$REPO_ROOT" && ruby scripts/test-workflow-contract.rb

core-test:
	cd "$$REPO_ROOT" && scripts/swift-test.sh

test: core-test
	cd "$$REPO_ROOT" && scripts/xcode-test.sh

build:
	cd "$$REPO_ROOT" && scripts/xcode-build.sh

root-test:
	cd "$$REPO_ROOT" && scripts/test-makefile-root.sh

verify: structural test build root-test

check: verify
