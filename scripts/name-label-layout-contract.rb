#!/usr/bin/env ruby
# frozen_string_literal: true

module NameLabelLayoutContract
  SIGNATURE = 'func constructNameLabel()'
  ASSIGNMENT = /nameLabel\.autoresizingMask\s*=\s*([^\n]+(?:\n\s+[^\n]+)?)/

  module_function

  def validate(source)
    method = method_source(source, SIGNATURE)
    return ['constructNameLabel could not be extracted'] unless method

    assignments = method.scan(ASSIGNMENT).flatten
    failures = []
    failures << 'must assign the name label autoresizing mask exactly once' unless assignments.length == 1

    assignment = assignments.first.to_s
    failures << 'must follow info view width changes' unless assignment.include?('UIViewAutoresizing.FlexibleWidth')
    failures << 'must follow info view height changes' unless assignment.include?('UIViewAutoresizing.FlexibleHeight')

    assignment_index = method.index('nameLabel.autoresizingMask')
    attachment_index = method.index('infoView.addSubview(nameLabel)')
    unless assignment_index && attachment_index && assignment_index < attachment_index
      failures << 'must configure autoresizing before attaching the name label'
    end

    failures
  end

  def method_source(source, signature)
    start_index = source.index(signature)
    return nil unless start_index

    opening_brace = source.index('{', start_index)
    return nil unless opening_brace

    block = balanced_block(source, opening_brace)
    block ? source[start_index...opening_brace] + block : nil
  end

  def balanced_block(source, opening_brace)
    depth = 0
    index = opening_brace

    while index < source.length
      depth += 1 if source[index, 1] == '{'
      depth -= 1 if source[index, 1] == '}'
      return source[opening_brace..index] if depth.zero?

      index += 1
    end

    nil
  end
end
