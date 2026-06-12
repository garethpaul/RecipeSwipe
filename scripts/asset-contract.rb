#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'

module AssetContract
  MAX_ASSET_BYTES = 5 * 1024 * 1024
  PNG_SIGNATURE = "\x89PNG\r\n\x1A\n".b
  JPEG_SIGNATURE = "\xFF\xD8\xFF".b
  SIGNATURES = {
    '.jpeg' => JPEG_SIGNATURE,
    '.jpg' => JPEG_SIGNATURE,
    '.png' => PNG_SIGNATURE
  }.freeze

  module_function

  def validate_reference(imageset_dir, filename)
    failures = []
    unless plain_basename?(filename)
      return ['asset filename must be a plain basename without path traversal']
    end

    file_path = Pathname.new(imageset_dir).join(filename)
    return ["points at missing image file #{filename}"] unless file_path.file?

    size = file_path.size
    failures << "points at empty image file #{filename}" if size.zero?
    if size > MAX_ASSET_BYTES
      failures << "points at oversized image file #{filename}: #{size} bytes exceeds #{MAX_ASSET_BYTES}"
    end

    extension = File.extname(filename).downcase
    signature = SIGNATURES[extension]
    if signature.nil?
      failures << "uses unsupported image extension #{extension.empty? ? '(none)' : extension} for #{filename}"
    elsif size.positive? && File.binread(file_path, signature.bytesize) != signature
      failures << "image file #{filename} does not match its #{extension} signature"
    end

    failures
  end

  def plain_basename?(filename)
    filename.is_a?(String) &&
      !filename.empty? &&
      filename != '.' &&
      filename != '..' &&
      !filename.include?('/') &&
      !filename.include?('\\') &&
      !Pathname.new(filename).absolute? &&
      File.basename(filename) == filename
  end
end
