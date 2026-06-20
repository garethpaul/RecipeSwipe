#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'pathname'
require_relative 'asset-contract'
require_relative 'swipe-state-contract'

root = File.expand_path('..', __dir__)
failures = SwipeStateContract.validate(root)
asset_root = Pathname.new(root).join('RecipeSwipe/Images.xcassets')

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
