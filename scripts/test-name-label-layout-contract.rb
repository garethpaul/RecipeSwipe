#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'name-label-layout-contract'

class NameLabelLayoutContractTest < Minitest::Test
  VALID_SOURCE = <<~SWIFT
    func constructNameLabel() {
        let nameLabel: UILabel = UILabel(frame: infoView.bounds)
        nameLabel.autoresizingMask = UIViewAutoresizing.FlexibleWidth |
            UIViewAutoresizing.FlexibleHeight
        nameLabel.text = recipe.name
        infoView.addSubview(nameLabel)
    }
  SWIFT

  def test_accepts_width_and_height_autoresizing_before_attachment
    assert_empty NameLabelLayoutContract.validate(VALID_SOURCE)
  end

  def test_rejects_hostile_layout_mutations
    mutations = {
      'width removed' => VALID_SOURCE.sub('UIViewAutoresizing.FlexibleWidth |', 'UIViewAutoresizing.None |'),
      'height removed' => VALID_SOURCE.sub('UIViewAutoresizing.FlexibleHeight', 'UIViewAutoresizing.None'),
      'wrong target' => VALID_SOURCE.sub('nameLabel.autoresizingMask', 'infoView.autoresizingMask'),
      'mask overwritten' => VALID_SOURCE.sub(
        'nameLabel.text = recipe.name',
        "nameLabel.autoresizingMask = UIViewAutoresizing.None\n    nameLabel.text = recipe.name"
      ),
      'configured after attachment' => VALID_SOURCE.sub(
        "    nameLabel.autoresizingMask = UIViewAutoresizing.FlexibleWidth |\n        UIViewAutoresizing.FlexibleHeight\n    nameLabel.text = recipe.name\n    infoView.addSubview(nameLabel)",
        "    nameLabel.text = recipe.name\n    infoView.addSubview(nameLabel)\n    nameLabel.autoresizingMask = UIViewAutoresizing.FlexibleWidth |\n        UIViewAutoresizing.FlexibleHeight"
      )
    }

    mutations.each do |description, source|
      refute_empty NameLabelLayoutContract.validate(source), "expected #{description} to fail"
    end
  end

  def test_rejects_missing_or_unbalanced_method
    refute_empty NameLabelLayoutContract.validate('func unrelated() {}')
    refute_empty NameLabelLayoutContract.validate(VALID_SOURCE.sub(/}\s*\z/, ''))
  end

  def test_wires_contract_into_source_and_make_gates
    checker_source = File.read(File.expand_path('check-ios-source.rb', __dir__))
    makefile = File.read(File.expand_path('../Makefile', __dir__))

    assert_includes checker_source, 'NameLabelLayoutContract.validate'
    assert_equal 2, makefile.scan('ruby scripts/test-name-label-layout-contract.rb').length
  end
end
