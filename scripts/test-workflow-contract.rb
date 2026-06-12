#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'workflow-contract'

BASELINE = <<~YAML
  name: Check

  on:
    push:
      branches: [master]
    pull_request:
    workflow_dispatch:

  permissions:
    contents: read

  concurrency:
    group: check-${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true

  jobs:
    structural:
      runs-on: macos-15
      timeout-minutes: 10
      steps:
        - name: Check out repository
          uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
          with:
            persist-credentials: false
        - name: Validate archived iOS source
          run: make structural
YAML

def assert_valid(workflow)
  failures = WorkflowContract.validate(workflow)
  abort("expected valid workflow, got: #{failures.join(', ')}") unless failures.empty?
end

def assert_invalid(description, workflow)
  abort("expected #{description} mutation to fail") if WorkflowContract.validate(workflow).empty?
end

def mutate(description, target, replacement)
  mutated = BASELINE.sub(target, replacement)
  abort("#{description} mutation did not alter the fixture") if mutated == BASELINE

  mutated
end

assert_valid(BASELINE)

mutations = {
  'contradictory credentials' => mutate('contradictory credentials', 'persist-credentials: false', "persist-credentials: false\n          persist-credentials: true"),
  'relocated credentials' => mutate('relocated credentials', "        with:\n          persist-credentials: false\n", '').sub('permissions:', "persist-credentials: false\n\npermissions:"),
  'floating checkout action' => mutate('floating checkout action', WorkflowContract::CHECKOUT_ACTION, 'actions/checkout@v6'),
  'extra action' => mutate('extra action', '      - name: Validate archived iOS source', "      - uses: example/unreviewed-action@v1\n      - name: Validate archived iOS source"),
  'write permission' => mutate('write permission', 'contents: read', "contents: read\n  issues: write"),
  'missing push validation' => mutate('missing push validation', "  push:\n    branches: [master]\n", ''),
  'missing pull request validation' => mutate('missing pull request validation', "  pull_request:\n", ''),
  'missing manual dispatch' => mutate('missing manual dispatch', "  workflow_dispatch:\n", ''),
  'duplicate runner' => mutate('duplicate runner', '    runs-on: macos-15', "    runs-on: macos-15\n    runs-on: macos-15"),
  'unbounded job' => mutate('unbounded job', "    timeout-minutes: 10\n", ''),
  'continued failure' => mutate('continued failure', '    steps:', "    continue-on-error: true\n    steps:"),
  'legacy Xcode build' => mutate('legacy Xcode build', 'run: make structural', 'run: xcodebuild build'),
  'archived pod installation' => mutate('archived pod installation', 'run: make structural', 'run: pod install && make structural')
}

mutations.each do |description, workflow|
  assert_invalid(description, workflow)
end

puts "workflow contract tests passed (#{mutations.length} mutations rejected)."
