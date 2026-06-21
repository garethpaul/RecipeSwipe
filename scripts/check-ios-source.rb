#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'pathname'
require_relative 'asset-contract'
require_relative 'swipe-state-contract'

root = File.expand_path('..', __dir__)
failures = SwipeStateContract.validate(root)
asset_root = Pathname.new(root).join('RecipeSwipe/Images.xcassets')
makefile = File.read(File.join(root, 'Makefile'))

[
  'ifneq ($(origin MAKEFILE_LIST),file)',
  '$(error MAKEFILE_LIST must not be overridden)',
  'override REPO_ROOT := $(shell path=',
  '/bin/sed',
  '/usr/bin/dirname',
  '/bin/pwd -P',
  'root-test:',
  'scripts/test-makefile-root.sh',
  'verify: structural test build root-test'
].each do |contract|
  failures << "Makefile must preserve #{contract}" unless makefile.include?(contract)
end

root_test = File.read(File.join(root, 'scripts/test-makefile-root.sh'))
['RecipeSwipe', '24 target/override cases', '2 MAKEFILE_LIST rejection cases', 'MAKEFILE_LIST must not be overridden'].each do |contract|
  failures << "Makefile root test must preserve #{contract}" unless root_test.include?(contract)
end

root_plan = File.read(File.join(root, 'docs/plans/2026-06-21-safe-make-root.md'))
['## Status: Completed', 'seven pre-existing public Make targets plus the root regression gate', '24 target and `REPO_ROOT` override cases', 'Command-line and environment `MAKEFILE_LIST` overrides failed closed'].each do |evidence|
  failures << "safe Make root plan must preserve #{evidence}" unless root_plan.include?(evidence)
end

Dir.glob(asset_root.join('**/Contents.json')).sort.each do |json_path|
  contents = JSON.parse(File.read(json_path))
  Array(contents['images']).each do |image|
    filename = image['filename']
    next if filename.nil? || filename.empty?

    AssetContract.validate_reference(Pathname.new(json_path).dirname, filename).each do |failure|
      relative_path = Pathname.new(json_path).relative_path_from(Pathname.new(root))
      failures << "#{relative_path} #{failure}"
    end
  end
rescue JSON::ParserError => error
  failures << "#{json_path} is not valid JSON: #{error.message}"
end

if failures.empty?
  puts 'iOS source checks passed'
else
  warn "iOS source checks failed:\n- #{failures.join("\n- ")}"
  exit 1
end
