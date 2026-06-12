# frozen_string_literal: true

module WorkflowContract
  CHECKOUT_ACTION = 'actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10'
  CHECKOUT_BLOCK = [
    '      - name: Check out repository',
    "        uses: #{CHECKOUT_ACTION} # v6.0.3",
    '        with:',
    '          persist-credentials: false'
  ].join("\n")

  module_function

  def validate(workflow)
    failures = []
    actions = workflow.scan(/^[ \t]*(?:-[ \t]*)?uses:[ \t]*(\S+)(?:[ \t]+#.*)?$/).flatten

    failures << 'validate pushes to master' unless workflow.include?("  push:\n    branches: [master]")
    failures << 'validate pull requests' unless workflow.scan(/^  pull_request:$/).length == 1
    failures << 'allow manual workflow dispatch exactly once' unless workflow.scan(/^  workflow_dispatch:$/).length == 1
    failures << 'cancel superseded workflow runs exactly once' unless workflow.scan(/^  cancel-in-progress: true$/).length == 1
    failures << 'use the fixed macOS 15 runner exactly once' unless workflow.scan(/^    runs-on: macos-15$/).length == 1
    failures << 'bound structural validation to ten minutes exactly once' unless workflow.scan(/^    timeout-minutes: 10$/).length == 1
    failures << 'use the exact credential-free checkout contract' unless workflow.include?(CHECKOUT_BLOCK)
    failures << 'use only the reviewed checkout action' unless actions == [CHECKOUT_ACTION]
    failures << 'configure checkout credential persistence exactly once' unless workflow.scan(/persist-credentials:/).length == 1
    failures << 'declare workflow permissions exactly once' unless workflow.scan(/^permissions:$/).length == 1
    failures << 'use read-only repository contents permission' unless workflow.match?(/^permissions:\n  contents: read$/)
    failures << 'not request write permissions' if workflow.match?(/^[ \t]+[A-Za-z-]+:[ \t]+write[ \t]*$/)
    failures << 'run the canonical structural validation gate exactly once' unless workflow.scan(/^        run: make structural$/).length == 1
    failures << 'not allow structural validation failures' if workflow.include?('continue-on-error')
    failures << 'not run legacy Xcode builds' if workflow.include?('xcodebuild')
    failures << 'not install archived CocoaPods dependencies' if workflow.match?(/\bpod install\b/)

    failures
  end
end
