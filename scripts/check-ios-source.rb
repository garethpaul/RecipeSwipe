#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'pathname'
require 'set'

ROOT = Pathname.new(__dir__).parent.expand_path

def rel(path)
  Pathname.new(path).relative_path_from(ROOT).to_s
end

failures = []

swift_files = Dir.glob(ROOT.join('{RecipeSwipe,RecipeSwipeTests}/**/*.swift')).sort
uikit_symbols = %w[
  UIImage UIImageView UIColor UIView UIViewController UILabel UIButton UIFont
  UIControlState UIViewAutoresizing UIViewContentMode NSTextAlignment
]

swift_files.each do |path|
  source = File.read(path)
  next if source.match?(/^\s*import\s+UIKit\b/)

  used_symbols = uikit_symbols.select { |symbol| source.match?(/\b#{Regexp.escape(symbol)}\b/) }
  next if used_symbols.empty?

  failures << "#{rel(path)} uses UIKit types without importing UIKit: #{used_symbols.join(', ')}"
end

asset_root = ROOT.join('RecipeSwipe/Images.xcassets')
asset_names = Set.new(
  Dir.glob(asset_root.join('**/*.imageset')).map { |path| File.basename(path, '.imageset') }
)

swift_files.each do |path|
  source = File.read(path)
  source.scan(/UIImage\s*\(\s*named:\s*"([^"]+)"/).flatten.each do |image_name|
    next if asset_names.include?(image_name)

    basename = File.basename(image_name, '.*')
    if asset_names.include?(basename)
      failures << "#{rel(path)} references UIImage(named: \"#{image_name}\"); use asset catalog name \"#{basename}\""
    else
      failures << "#{rel(path)} references missing image asset \"#{image_name}\""
    end
  end
end

Dir.glob(asset_root.join('**/Contents.json')).sort.each do |json_path|
  contents = JSON.parse(File.read(json_path))
  Array(contents['images']).each do |image|
    filename = image['filename']
    next if filename.nil? || filename.empty?

    file_path = Pathname.new(json_path).dirname.join(filename)
    failures << "#{rel(json_path)} points at missing image file #{filename}" unless file_path.file?
  end
rescue JSON::ParserError => e
  failures << "#{rel(json_path)} is not valid JSON: #{e.message}"
end

pod_lock = ROOT.join('Podfile.lock')
manifest_lock = ROOT.join('Pods/Manifest.lock')
if pod_lock.file? && manifest_lock.file?
  failures << 'Podfile.lock and Pods/Manifest.lock differ; run pod install before committing' unless pod_lock.read == manifest_lock.read
else
  failures << 'Podfile.lock is missing' unless pod_lock.file?
  failures << 'Pods/Manifest.lock is missing' unless manifest_lock.file?
end

project_file = ROOT.join('RecipeSwipe.xcodeproj/project.pbxproj')
if project_file.file?
  project_source = project_file.read
  project_source.scan(/SWIFT_OBJC_BRIDGING_HEADER = ([^;]+);/).flatten.each do |raw_value|
    header_path = raw_value.delete('"').strip
    if header_path.start_with?('/')
      failures << "RecipeSwipe.xcodeproj/project.pbxproj uses absolute bridging header path #{header_path}"
      next
    end

    failures << "RecipeSwipe.xcodeproj/project.pbxproj references missing bridging header #{header_path}" unless ROOT.join(header_path).file?
  end
else
  failures << 'RecipeSwipe.xcodeproj/project.pbxproj is missing'
end

if failures.empty?
  puts 'iOS source checks passed'
else
  warn "iOS source checks failed:\n- #{failures.join("\n- ")}"
  exit 1
end
