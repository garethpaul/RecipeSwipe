#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
ATTACKER_ROOT=/tmp/recipeswipe-attacker-root
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/recipeswipe-root-control-XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
unset MAKEFILES MAKEFILE_LIST

CONTROL_DIR="$TEMP_ROOT/control"
CHECKOUT="$TEMP_ROOT/RecipeSwipe's [gate] \"quoted\" ; \`touch RECIPESWIPE_BACKTICK_MARKER\`"
COMMAND_LOG="$TEMP_ROOT/commands.log"
FAKE_SHELL_LOG="$TEMP_ROOT/fake-shell.log"
SHADOWED_TOOL_LOG="$TEMP_ROOT/shadowed-tool.log"
mkdir "$CONTROL_DIR" "$CHECKOUT" "$CHECKOUT/scripts" "$CHECKOUT/bin"
CHECKOUT=$(CDPATH='' cd -- "$CHECKOUT" && pwd -P)
MAKEFILE="$CHECKOUT/Makefile"
cp "$ROOT_DIR/Makefile" "$MAKEFILE"

cat >"$CHECKOUT/bin/ruby" <<'EOF'
#!/bin/sh
printf '%s|ruby %s\n' "$PWD" "$*" >> "$RECIPESWIPE_COMMAND_LOG"
EOF

write_logger() {
  file=$1
  cat >"$file" <<'EOF'
#!/bin/sh
printf '%s|%s\n' "$PWD" "$0" >> "$RECIPESWIPE_COMMAND_LOG"
EOF
  chmod +x "$file"
}

for script in swift-test.sh xcode-test.sh xcode-build.sh test-makefile-root.sh; do
  write_logger "$CHECKOUT/scripts/$script"
done
chmod +x "$CHECKOUT/bin/ruby"

for tool in dirname pwd sed; do
  cat >"$CHECKOUT/bin/$tool" <<EOF
#!/bin/sh
printf '%s\n' '$tool' >> '$SHADOWED_TOOL_LOG'
exit 99
EOF
  chmod +x "$CHECKOUT/bin/$tool"
done

FAKE_SHELL="$TEMP_ROOT/fake-shell"
cat >"$FAKE_SHELL" <<EOF
#!/bin/sh
printf '%s\n' invoked >> '$FAKE_SHELL_LOG'
exec /bin/sh "\$@"
EOF
chmod +x "$FAKE_SHELL"

assert_commands_stayed_in_checkout() {
  scenario=$1
  target=$2
  if [ ! -s "$COMMAND_LOG" ]; then
    printf '%s\n' "$scenario $target executed no quality command" >&2
    exit 1
  fi
  while IFS= read -r command; do
    case "$command" in
      "$CHECKOUT|"*) ;;
      *)
        printf '%s\n' "$scenario $target escaped the checkout: $command" >&2
        exit 1
        ;;
    esac
  done <"$COMMAND_LOG"
}

assert_output_contains() {
  expected=$1
  file=$2
  scenario=$3
  if ! grep -Fq "$expected" "$file"; then
    printf '%s\n' "$scenario did not report: $expected" >&2
    cat "$file" >&2
    exit 1
  fi
}

run_case() {
  scenario=$1
  target=$2
  mode=$3
  rm -f "$COMMAND_LOG"
  output="$TEMP_ROOT/output"
  set +e
  case "$mode" in
    default)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" "$target") >"$output" 2>&1
      ;;
    command-root)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" "REPO_ROOT=$ATTACKER_ROOT" "$target") >"$output" 2>&1
      ;;
    environment-root)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" REPO_ROOT="$ATTACKER_ROOT" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" "$target") >"$output" 2>&1
      ;;
    command-shell)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" "SHELL=$FAKE_SHELL" "$target") >"$output" 2>&1
      ;;
    environment-shell)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SHELL="$FAKE_SHELL" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" "$target") >"$output" 2>&1
      ;;
    command-flags)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" '.SHELLFLAGS=-eu -c' "$target") >"$output" 2>&1
      ;;
    environment-flags)
      (cd "$CONTROL_DIR" && env '.SHELLFLAGS=-eu -c' PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" "$target") >"$output" 2>&1
      ;;
    *)
      printf '%s\n' "unknown test mode: $mode" >&2
      exit 1
      ;;
  esac
  result=$?
  set -e
  if [ "$result" -ne 0 ]; then
    printf '%s\n' "$scenario $target failed" >&2
    cat "$output" >&2
    exit 1
  fi
  assert_commands_stayed_in_checkout "$scenario" "$target"
}

for target in build check core-test lint root-test structural test verify; do
  run_case default "$target" default
  run_case command-root "$target" command-root
  run_case environment-root "$target" environment-root
  run_case command-shell "$target" command-shell
  run_case environment-shell "$target" environment-shell
  run_case command-flags "$target" command-flags
  run_case environment-flags "$target" environment-flags
done

if [ -e "$CONTROL_DIR/RECIPESWIPE_BACKTICK_MARKER" ]; then
  printf '%s\n' "checkout path executed a command substitution" >&2
  exit 1
fi
if [ -e "$FAKE_SHELL_LOG" ]; then
  printf '%s\n' "caller-controlled SHELL was executed" >&2
  exit 1
fi
if [ -e "$SHADOWED_TOOL_LOG" ]; then
  printf '%s\n' "caller PATH shadowed a root-resolution tool" >&2
  exit 1
fi

if (cd "$CONTROL_DIR" && make --no-print-directory --file "$MAKEFILE" MAKEFILE_LIST=/tmp/untrusted check) >"$TEMP_ROOT/command-list.out" 2>&1; then
  printf '%s\n' "command MAKEFILE_LIST override unexpectedly passed" >&2
  exit 1
fi
assert_output_contains "MAKEFILE_LIST must not be overridden" "$TEMP_ROOT/command-list.out" "command MAKEFILE_LIST override"

if (cd "$CONTROL_DIR" && MAKEFILE_LIST=/tmp/untrusted make --environment-overrides --no-print-directory --file "$MAKEFILE" check) >"$TEMP_ROOT/environment-list.out" 2>&1; then
  printf '%s\n' "environment MAKEFILE_LIST override unexpectedly passed" >&2
  exit 1
fi
assert_output_contains "MAKEFILE_LIST must not be overridden" "$TEMP_ROOT/environment-list.out" "environment MAKEFILE_LIST override"

PRELOADED_MAKEFILE="$TEMP_ROOT/preloaded.mk"
printf '%s\n' 'REPO_ROOT := /tmp/preloaded-attacker-root' >"$PRELOADED_MAKEFILE"
rm -f "$COMMAND_LOG"
if (cd "$CONTROL_DIR" && MAKEFILES="$PRELOADED_MAKEFILE" PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" check) >"$TEMP_ROOT/preloaded.out" 2>&1; then
  printf '%s\n' "MAKEFILES preload unexpectedly passed" >&2
  exit 1
fi
assert_output_contains "MAKEFILES must be empty" "$TEMP_ROOT/preloaded.out" "MAKEFILES preload"
if [ -e "$COMMAND_LOG" ]; then
  printf '%s\n' "MAKEFILES preload reached a quality command" >&2
  exit 1
fi

LATER_MAKEFILE="$TEMP_ROOT/later.mk"
LATER_MARKER="$TEMP_ROOT/later-marker"
cat >"$LATER_MAKEFILE" <<EOF
.PHONY: build check core-test lint root-test structural test verify
build check core-test lint root-test structural test verify:
	@touch '$LATER_MARKER'
EOF
rm -f "$COMMAND_LOG" "$LATER_MARKER"
if (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" --file "$LATER_MAKEFILE" check) >"$TEMP_ROOT/later.out" 2>&1; then
  printf '%s\n' "later multiple -f Makefile unexpectedly passed" >&2
  exit 1
fi
assert_output_contains "has both : and :: entries" "$TEMP_ROOT/later.out" "later multiple -f Makefile"
if [ -e "$LATER_MARKER" ] || [ -e "$COMMAND_LOG" ]; then
  printf '%s\n' "later multiple -f Makefile reached a quality command" >&2
  exit 1
fi

COMBINED_MAKEFILE="$TEMP_ROOT/combined-later.mk"
COMBINED_MARKER="$TEMP_ROOT/combined-later-marker"
cat >"$COMBINED_MAKEFILE" <<EOF
override REPOSITORY_MAKEFILE := \$(value MAKEFILE_LIST)
build check core-test lint root-test structural test verify:
	@printf '%s\n' '\$@' >> '$COMBINED_MARKER'
EOF
rm -f "$COMMAND_LOG" "$COMBINED_MARKER"
if (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" --file "$COMBINED_MAKEFILE" check) >"$TEMP_ROOT/combined-later.out" 2>&1; then
  printf '%s\n' "combined later Makefile authority bypass unexpectedly passed" >&2
  exit 1
fi
if [ -e "$COMBINED_MARKER" ] || [ -e "$COMMAND_LOG" ]; then
  printf '%s\n' "combined later Makefile authority bypass reached a quality command" >&2
  exit 1
fi
assert_output_contains "has both : and :: entries" "$TEMP_ROOT/combined-later.out" "combined later Makefile authority bypass"

TARGET_SHELL_MAKEFILE="$TEMP_ROOT/target-shell-later.mk"
TARGET_SHELL_LOG="$TEMP_ROOT/target-shell.log"
cat >"$TARGET_SHELL_MAKEFILE" <<EOF
build check core-test lint root-test structural test verify: SHELL := $FAKE_SHELL
build check core-test lint root-test structural test verify: .SHELLFLAGS := -c
EOF
rm -f "$COMMAND_LOG" "$TARGET_SHELL_LOG" "$FAKE_SHELL_LOG"
if (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" --file "$TARGET_SHELL_MAKEFILE" lint) >"$TEMP_ROOT/target-shell.out" 2>&1; then
  printf '%s\n' "later target-specific shell unexpectedly passed" >&2
  exit 1
fi
assert_output_contains "additional Makefiles are not supported" "$TEMP_ROOT/target-shell.out" "later target-specific shell"
if [ -e "$FAKE_SHELL_LOG" ] || [ -e "$COMMAND_LOG" ]; then
  printf '%s\n' "later target-specific shell intercepted repository validation" >&2
  exit 1
fi

DOLLAR_CHECKOUT="$TEMP_ROOT/RecipeSwipe \$(touch RECIPESWIPE_DOLLAR_MARKER)"
mkdir "$DOLLAR_CHECKOUT"
cp "$ROOT_DIR/Makefile" "$DOLLAR_CHECKOUT/Makefile"
if (cd "$CONTROL_DIR" && make --no-print-directory --file "$DOLLAR_CHECKOUT/Makefile" check) >"$TEMP_ROOT/dollar.out" 2>&1; then
  printf '%s\n' "dollar-command checkout path unexpectedly passed" >&2
  cat "$TEMP_ROOT/dollar.out" >&2
  exit 1
fi
if [ -e "$CONTROL_DIR/RECIPESWIPE_DOLLAR_MARKER" ]; then
  printf '%s\n' "checkout path executed dollar command substitution" >&2
  cat "$TEMP_ROOT/dollar.out" >&2
  exit 1
fi

for flag in n t q i; do
  if (cd "$CONTROL_DIR" && MAKEFLAGS="-$flag" make --no-print-directory --file "$MAKEFILE" check) >"$TEMP_ROOT/makeflags-$flag.out" 2>&1; then
    printf '%s\n' "MAKEFLAGS -$flag unexpectedly passed" >&2
    exit 1
  fi
  assert_output_contains "non-executing or error-ignoring MAKEFLAGS are not supported" "$TEMP_ROOT/makeflags-$flag.out" "MAKEFLAGS -$flag"
done

if (cd "$CONTROL_DIR" && make -n MAKEFLAGS= --no-print-directory --file "$MAKEFILE" check) >"$TEMP_ROOT/makeflags-override.out" 2>&1; then
  printf '%s\n' "command-line MAKEFLAGS override unexpectedly passed" >&2
  exit 1
fi
assert_output_contains "MAKEFLAGS must not be overridden" "$TEMP_ROOT/makeflags-override.out" "command-line MAKEFLAGS override"

EARLIER_MAKEFILE="$TEMP_ROOT/earlier.mk"
printf '%s\n' '# Explicit caller-controlled Makefile.' >"$EARLIER_MAKEFILE"
rm -f "$COMMAND_LOG"
if (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$EARLIER_MAKEFILE" --file "$MAKEFILE" check) >"$TEMP_ROOT/multiple.out" 2>&1; then
  printf '%s\n' "multiple -f Makefiles unexpectedly passed" >&2
  exit 1
fi
assert_output_contains "repository Makefile path could not be resolved" "$TEMP_ROOT/multiple.out" "earlier multiple -f Makefile"
if [ -e "$COMMAND_LOG" ]; then
  printf '%s\n' "multiple -f Makefiles reached a quality command" >&2
  exit 1
fi

BOUNDARY_TEXT="GNU Make \`override\` directives"
grep -Fq "$BOUNDARY_TEXT" "$ROOT_DIR/README.md"
grep -Fq 'caller-added double-colon recipes' "$ROOT_DIR/README.md"
grep -Fq "$BOUNDARY_TEXT" "$ROOT_DIR/docs/plans/2026-06-21-safe-make-root.md"
grep -Fq 'caller-added double-colon recipes' "$ROOT_DIR/docs/plans/2026-06-21-safe-make-root.md"

printf '%s\n' "Makefile root tests passed: 56 executed target/authority cases, 2 MAKEFILE_LIST rejections, 1 MAKEFILES rejection, 3 multi-Makefile rejections including the combined eight-recipe bypass, 1 later target-specific shell rejection, 5 MAKEFLAGS rejections, 1 dollar-path fail-closed case, and documented override/double-colon caller boundaries"
