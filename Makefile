.PHONY: __repository-make-authority build check core-test lint root-test structural test verify

PUBLIC_TARGETS := build check core-test lint root-test structural test verify

override SHELL := /bin/sh
override .SHELLFLAGS := -c
$(PUBLIC_TARGETS) __repository-make-authority: override SHELL := /bin/sh
$(PUBLIC_TARGETS) __repository-make-authority: override .SHELLFLAGS := -c
ifneq ($(filter command line,$(origin MAKEFLAGS)),)
$(error MAKEFLAGS must not be overridden for repository verification)
endif
override REPOSITORY_MAKE_FIRST_FLAGS := $(firstword $(MAKEFLAGS))
ifneq ($(filter -%,$(REPOSITORY_MAKE_FIRST_FLAGS)),)
override REPOSITORY_MAKE_FIRST_FLAGS :=
endif
override REPOSITORY_MAKE_SHORT_FLAGS := $(REPOSITORY_MAKE_FIRST_FLAGS) $(filter-out --%,$(filter -%,$(MAKEFLAGS)))
ifneq ($(findstring n,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring t,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring q,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(findstring i,$(REPOSITORY_MAKE_SHORT_FLAGS)),)
$(error non-executing or error-ignoring MAKEFLAGS are not supported for repository verification)
endif
ifneq ($(strip $(MAKEFILES)),)
$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)
endif
override MAKEFILES :=
ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif
override REPOSITORY_MAKEFILE := $(value MAKEFILE_LIST)
override REPO_ROOT := $(shell path='$(subst ','"'"',$(value MAKEFILE_LIST))'; path=$$(printf '%s' "$$path" | /usr/bin/sed 's/^ //'); [ -f "$$path" ] || exit 1; directory=$$(/usr/bin/dirname -- "$$path"); CDPATH= cd -- "$$directory" && /bin/pwd -P)
export REPO_ROOT
ifeq ($(strip $(REPO_ROOT)),)
$(error repository Makefile path could not be resolved)
endif
override REPOSITORY_SHELL_LITERAL = $(subst $$,$$$$,$(subst ','"'"',$1))
override REPOSITORY_ROOT_LITERAL := $(call REPOSITORY_SHELL_LITERAL,$(REPO_ROOT))

$(PUBLIC_TARGETS):: __repository-make-authority

__repository-make-authority::
	@expected='$(subst ','"'"',$(value REPOSITORY_MAKEFILE))'; actual='$(subst ','"'"',$(value MAKEFILE_LIST))'; [ "$$actual" = "$$expected" ] || { printf '%s\n' 'additional Makefiles are not supported for repository verification' >&2; exit 2; }

lint::
	cd '$(REPOSITORY_ROOT_LITERAL)' && ruby scripts/check-ios-source.rb

structural:: lint
	cd '$(REPOSITORY_ROOT_LITERAL)' && ruby scripts/test-asset-contract.rb
	cd '$(REPOSITORY_ROOT_LITERAL)' && ruby scripts/test-swipe-state-contract.rb
	cd '$(REPOSITORY_ROOT_LITERAL)' && ruby scripts/test-xcode-runner-contract.rb
	cd '$(REPOSITORY_ROOT_LITERAL)' && ruby scripts/test-workflow-contract.rb

core-test::
	cd '$(REPOSITORY_ROOT_LITERAL)' && scripts/swift-test.sh

test:: core-test
	cd '$(REPOSITORY_ROOT_LITERAL)' && scripts/xcode-test.sh

build::
	cd '$(REPOSITORY_ROOT_LITERAL)' && scripts/xcode-build.sh

root-test::
	cd '$(REPOSITORY_ROOT_LITERAL)' && scripts/test-makefile-root.sh

verify:: structural test build root-test

check:: verify
