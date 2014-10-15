require 'waterfall/version'
require 'waterfall/predicates/base'
require 'waterfall/predicates/catch'
require 'waterfall/predicates/when_falsy'
require 'waterfall/predicates/chain'
require 'waterfall/predicates/chain_wf'
require 'waterfall/predicates/merge_wf'

module Waterfall

  attr_reader :rejection_reason, :wf_result

  def when_falsy(&block)
    handler = ::Waterfall::WhenFalsy.new(self, &block)
    _wf_run do
      handler.call
    end
    handler
  end

  # chain(:var_name, block)
  def chain(var_name = nil, &block)
    _wf_run do
      ::Waterfall::Chain
        .new(self, var_name, &block)
        .call
    end
  end

  # chain_wf(:mapping_hash, block)
  def chain_wf(mapping_hash = {}, &block)
    _wf_run do
      ::Waterfall::ChainWf
        .new(self, mapping_hash, &block)
        .call
    end
  end

  # merge_wf(block)
  def merge_wf(&block)
    _wf_run do
      ::Waterfall::MergeWf
        .new(self, &block)
        .call
    end
  end

  def catch(&block)
    ::Waterfall::Catch.new(self, &block).call
    self
  end

  def reject(obj)
    @rejection_reason = obj
  end

  def stop_waterfall?
    rejection_reason
  end

  def is_waterfall?
    true
  end

  def update_wf_result(key, value)
    @wf_result[key] = value
  end

  def _wf_run(&block)
    unless stop_waterfall?
      @wf_result ||= {}
      block.call
    end
    self
  end
end

class Wf
  include Waterfall
end

