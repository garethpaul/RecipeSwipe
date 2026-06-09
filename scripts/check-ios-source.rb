#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'pathname'
require 'set'

ROOT = Pathname.new(__dir__).parent.expand_path
CANONICAL_PLAN = ROOT.join('docs/plans/2026-06-08-recipeswipe-baseline.md')
DOCS_PLANS = Dir.glob(ROOT.join('docs/plans/*.md')).sort

def rel(path)
  Pathname.new(path).relative_path_from(ROOT).to_s
end

def swift_method_source(source, signature)
  start_index = source.index(signature)
  return nil unless start_index

  brace_index = source.index('{', start_index)
  return nil unless brace_index

  depth = 0
  index = brace_index
  while index < source.length
    character = source[index, 1]
    depth += 1 if character == '{'
    depth -= 1 if character == '}'
    return source[start_index..index] if depth.zero?

    index += 1
  end

  nil
end

failures = []

if DOCS_PLANS.empty?
  failures << 'docs/plans must contain at least one completed plan'
end

DOCS_PLANS.each do |plan_path|
  plan = File.read(plan_path)
  unless plan.include?('Status: Completed') && plan.include?('make check')
    failures << "#{rel(plan_path)} must record completed status and make check verification"
  end
end

if CANONICAL_PLAN.file?
  # The baseline plan stays canonical for the historical validator coverage.
else
  failures << "#{rel(CANONICAL_PLAN)} is missing"
end

swift_files = Dir.glob(ROOT.join('{RecipeSwipe,RecipeSwipeTests}/**/*.swift')).sort
uikit_symbols = %w[
  UIImage UIImageView UIColor UIView UIViewController UILabel UIButton UIFont
  UIControlState UIViewAutoresizing UIViewContentMode NSTextAlignment
]
network_markers = [
  'NSURLSession',
  'NSURLConnection',
  'NSURLRequest',
  'http://',
  'https://'
]

swift_files.each do |path|
  source = File.read(path)
  next if source.match?(/^\s*import\s+UIKit\b/)

  used_symbols = uikit_symbols.select { |symbol| source.match?(/\b#{Regexp.escape(symbol)}\b/) }
  next if used_symbols.empty?

  failures << "#{rel(path)} uses UIKit types without importing UIKit: #{used_symbols.join(', ')}"
end

swift_files.each do |path|
  source = File.read(path)
  used_markers = network_markers.select { |marker| source.include?(marker) }
  next if used_markers.empty?

  failures << "#{rel(path)} introduces network recipe-data markers before a data contract exists: #{used_markers.join(', ')}"
end

asset_root = ROOT.join('RecipeSwipe/Images.xcassets')
asset_names = Set.new(
  Dir.glob(asset_root.join('**/*.imageset')).map { |path| File.basename(path, '.imageset') }
)

swift_files.each do |path|
  source = File.read(path)
  if source.match?(/UIImage\s*\(\s*named:\s*"[^"]+"\s*\)\s*!/)
    failures << "#{rel(path)} force-unwraps UIImage(named:); use a checked fallback before creating recipe cards"
  end

  if source.include?('recipe!')
    failures << "#{rel(path)} force-unwraps a Recipe optional; unwrap recipe with if let before using it"
  end

  if source.include?('superview!')
    failures << "#{rel(path)} force-unwraps a superview; guard optional parent views before animating"
  end

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

picker_controller = ROOT.join('RecipeSwipe/RecipePickerViewController.swift')
if picker_controller.file?
  picker_source = picker_controller.read
  view_did_load_section = swift_method_source(picker_source, 'override func viewDidLoad()')

  if view_did_load_section.nil?
    failures << 'RecipePickerViewController.viewDidLoad could not be validated'
  else
    unless view_did_load_section.include?('self.loadInitialRecipeCards()')
      failures << 'RecipePickerViewController must load initial cards from the recipe fetch callback'
    end

    if view_did_load_section.include?('removeAtIndex')
      failures << 'RecipePickerViewController.viewDidLoad must not remove recipes before fetch completion'
    end
  end

  unless picker_source.include?('func loadInitialRecipeCards() -> Void')
    failures << 'RecipePickerViewController must define loadInitialRecipeCards()'
  end

  unless picker_source.include?('func swipeTopCard(direction: MDCSwipeDirection) -> Void')
    failures << 'RecipePickerViewController must define guarded swipeTopCard(direction:)'
  end

  if picker_source.include?('self.topCardView.mdc_swipe')
    failures << 'RecipePickerViewController button actions must not swipe topCardView without a RecipePickerView guard'
  end

  unless picker_source.include?('if let recipeView = self.topCardView as? RecipePickerView') &&
         picker_source.include?('recipeView.mdc_swipe(direction)')
    failures << 'RecipePickerViewController swipeTopCard must guard empty placeholder cards'
  end

  delegate_section = swift_method_source(picker_source, 'func view(view: UIView!, wasChosenWithDirection direction: MDCSwipeDirection)')
  if delegate_section.nil?
    failures << 'RecipePickerViewController swipe delegate could not be validated'
  else
    if delegate_section.match?(/\blet\s+\w+\s*=\s*view\s+as\s+RecipePickerView\b/)
      failures << 'RecipePickerViewController swipe delegate must not force-cast the chosen view'
    end

    unless delegate_section.include?('if let rpv = view as? RecipePickerView')
      failures << 'RecipePickerViewController swipe delegate must guard the chosen view type'
    end
  end

  background_section = swift_method_source(picker_source, 'func constructBackground()')
  if background_section.nil?
    failures << 'RecipePickerViewController.constructBackground could not be validated'
  else
    unless background_section.include?('CGRectGetHeight(bottomCardView.frame)')
      failures << 'RecipePickerViewController background image height must follow bottomCardView height'
    end

    if background_section.match?(/CGRectGetWidth\(bottomCardView\.frame\)\s*\)/)
      failures << 'RecipePickerViewController background image must not use bottomCardView width as height'
    end
  end

  {
    'constructNopeButton()' => ['nope', 'Skip recipe'],
    'constructLikeButton()' => ['like', 'Save recipe']
  }.each do |signature, (button_name, accessibility_label)|
    button_section = swift_method_source(picker_source, "func #{signature}")
    if button_section.nil?
      failures << "RecipePickerViewController.#{signature} could not be validated"
      next
    end

    if button_section.include?('insertSubview(button, atIndex: 0)')
      failures << "RecipePickerViewController #{button_name} button must not be inserted behind the empty-state background"
    end

    unless button_section.include?('self.view.addSubview(button)')
      failures << "RecipePickerViewController #{button_name} button must be added above background artwork"
    end

    unless button_section.include?("button.accessibilityLabel = \"#{accessibility_label}\"")
      failures << "RecipePickerViewController #{button_name} button must expose accessibility label #{accessibility_label.inspect}"
    end
  end
else
  failures << 'RecipeSwipe/RecipePickerViewController.swift is missing'
end

if failures.empty?
  puts 'iOS source checks passed'
else
  warn "iOS source checks failed:\n- #{failures.join("\n- ")}"
  exit 1
end
