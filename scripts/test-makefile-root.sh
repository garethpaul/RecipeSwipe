#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ATTACKER_ROOT=/tmp/recipeswipe-attacker-root
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/recipeswipe-root-control-XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
unset MAKEFILES MAKEFILE_LIST

CONTROL_DIR="$TEMP_ROOT/control"
CHECKOUT="$TEMP_ROOT/RecipeSwipe's [gate] \"quoted\" \`touch RECIPESWIPE_BACKTICK_MARKER\`"
COMMAND_LOG="$TEMP_ROOT/commands.log"
FAKE_SHELL_LOG="$TEMP_ROOT/fake-shell.log"
mkdir "$CONTROL_DIR" "$CHECKOUT" "$CHECKOUT/scripts" "$CHECKOUT/bin"
CHECKOUT=$(CDPATH= cd -- "$CHECKOUT" && pwd -P)
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

if (cd "$CONTROL_DIR" && make --no-print-directory --file "$MAKEFILE" MAKEFILE_LIST=/tmp/untrusted check) >"$TEMP_ROOT/command-list.out" 2>&1; then
  printf '%s\n' "command MAKEFILE_LIST override unexpectedly passed" >&2
  exit 1
fi
grep -Fq "MAKEFILE_LIST must not be overridden" "$TEMP_ROOT/command-list.out"

if (cd "$CONTROL_DIR" && MAKEFILE_LIST=/tmp/untrusted make --environment-overrides --no-print-directory --file "$MAKEFILE" check) >"$TEMP_ROOT/environment-list.out" 2>&1; then
  printf '%s\n' "environment MAKEFILE_LIST override unexpectedly passed" >&2
  exit 1
fi
grep -Fq "MAKEFILE_LIST must not be overridden" "$TEMP_ROOT/environment-list.out"

PRELOADED_MAKEFILE="$TEMP_ROOT/preloaded.mk"
printf '%s\n' 'REPO_ROOT := /tmp/preloaded-attacker-root' >"$PRELOADED_MAKEFILE"
rm -f "$COMMAND_LOG"
if (cd "$CONTROL_DIR" && MAKEFILES="$PRELOADED_MAKEFILE" PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$MAKEFILE" check) >"$TEMP_ROOT/preloaded.out" 2>&1; then
  printf '%s\n' "MAKEFILES preload unexpectedly passed" >&2
  exit 1
fi
grep -Fq "MAKEFILES must be empty" "$TEMP_ROOT/preloaded.out"
if [ -e "$COMMAND_LOG" ]; then
  printf '%s\n' "MAKEFILES preload reached a quality command" >&2
  exit 1
fi

EARLIER_MAKEFILE="$TEMP_ROOT/earlier.mk"
printf '%s\n' '# Explicit caller-controlled Makefile.' >"$EARLIER_MAKEFILE"
rm -f "$COMMAND_LOG"
if (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" RECIPESWIPE_COMMAND_LOG="$COMMAND_LOG" make --no-print-directory --file "$EARLIER_MAKEFILE" --file "$MAKEFILE" check) >"$TEMP_ROOT/multiple.out" 2>&1; then
  printf '%s\n' "multiple -f Makefiles unexpectedly passed" >&2
  exit 1
fi
grep -Fq "repository Makefile path could not be resolved" "$TEMP_ROOT/multiple.out"
if [ -e "$COMMAND_LOG" ]; then
  printf '%s\n' "multiple -f Makefiles reached a quality command" >&2
  exit 1
fi

printf '%s\n' "Makefile root tests passed: 56 executed target/authority cases, 2 MAKEFILE_LIST rejections, 1 MAKEFILES rejection, and 1 multi-Makefile rejection"
