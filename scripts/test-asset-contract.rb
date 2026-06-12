#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'minitest/autorun'
require 'tmpdir'
require_relative 'asset-contract'

class AssetContractTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir('recipeswipe-assets-')
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def write_asset(filename, contents)
    path = File.join(@directory, filename)
    File.binwrite(path, contents)
    path
  end

  def test_accepts_png_and_jpeg_signatures
    write_asset('image.png', AssetContract::PNG_SIGNATURE + 'png-data')
    write_asset('photo.jpg', AssetContract::JPEG_SIGNATURE + 'jpeg-data')
    write_asset('photo.jpeg', AssetContract::JPEG_SIGNATURE + 'jpeg-data')

    assert_empty AssetContract.validate_reference(@directory, 'image.png')
    assert_empty AssetContract.validate_reference(@directory, 'photo.jpg')
    assert_empty AssetContract.validate_reference(@directory, 'photo.jpeg')
  end

  def test_keeps_the_reviewed_asset_size_limit
    assert_equal 5 * 1024 * 1024, AssetContract::MAX_ASSET_BYTES
  end

  def test_keeps_canonical_png_and_jpeg_signatures
    assert_equal [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a].pack('C*'), AssetContract::PNG_SIGNATURE
    assert_equal [0xff, 0xd8, 0xff].pack('C*'), AssetContract::JPEG_SIGNATURE
  end

  def test_wires_asset_validation_into_source_and_make_gates
    checker_source = File.read(File.expand_path('check-ios-source.rb', __dir__))
    makefile = File.read(File.expand_path('../Makefile', __dir__))

    assert_includes checker_source, 'AssetContract.validate_reference'
    assert_equal 2, makefile.scan('ruby scripts/test-asset-contract.rb').length
  end

  def test_rejects_non_basename_and_traversal_filenames
    [nil, '', '.', '..', '../photo.jpg', 'nested/photo.jpg', 'nested\\photo.jpg', '/tmp/photo.jpg'].each do |filename|
      assert_equal ['asset filename must be a plain basename without path traversal'],
                   AssetContract.validate_reference(@directory, filename)
    end
  end

  def test_rejects_missing_files
    assert_equal ['points at missing image file missing.png'],
                 AssetContract.validate_reference(@directory, 'missing.png')
  end

  def test_rejects_empty_files
    write_asset('empty.png', '')

    assert_includes AssetContract.validate_reference(@directory, 'empty.png'),
                    'points at empty image file empty.png'
  end

  def test_rejects_oversized_files
    path = write_asset('large.png', AssetContract::PNG_SIGNATURE)
    File.truncate(path, AssetContract::MAX_ASSET_BYTES + 1)

    assert_includes AssetContract.validate_reference(@directory, 'large.png'),
                    "points at oversized image file large.png: #{AssetContract::MAX_ASSET_BYTES + 1} bytes exceeds #{AssetContract::MAX_ASSET_BYTES}"
  end

  def test_rejects_unsupported_extensions
    write_asset('image.gif', 'GIF89a')

    assert_includes AssetContract.validate_reference(@directory, 'image.gif'),
                    'uses unsupported image extension .gif for image.gif'
  end

  def test_rejects_missing_extensions
    write_asset('image', AssetContract::PNG_SIGNATURE)

    assert_includes AssetContract.validate_reference(@directory, 'image'),
                    'uses unsupported image extension (none) for image'
  end

  def test_rejects_extension_signature_mismatches
    write_asset('image.png', AssetContract::JPEG_SIGNATURE + 'jpeg-data')
    write_asset('photo.jpg', AssetContract::PNG_SIGNATURE + 'png-data')

    assert_includes AssetContract.validate_reference(@directory, 'image.png'),
                    'image file image.png does not match its .png signature'
    assert_includes AssetContract.validate_reference(@directory, 'photo.jpg'),
                    'image file photo.jpg does not match its .jpg signature'
  end
end
