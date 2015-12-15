require 'ostruct'
require 'waterfall/version'
require 'waterfall/predicates/base'
require 'waterfall/predicates/on_dam'
require 'waterfall/predicates/when_falsy'
require 'waterfall/predicates/when_truthy'
require 'waterfall/predicates/chain'

module Waterfall

  attr_reader :error_pool, :outflow, :flowing, :_wf_rolled_back

  def when_falsy(&block)
    handler = ::Waterfall::WhenFalsy.new(self)
    _wf_run { handler.call(&block) }
    handler
  end

  def when_truthy(&block)
    handler = ::Waterfall::WhenTruthy.new(self)
    _wf_run { handler.call(&block) }
    handler
  end

  def chain(mapping_or_var_name = nil, &block)
    _wf_run do
      ::Waterfall::Chain
        .new(self, mapping_or_var_name)
        .call(&block)
    end
  end

  def chain_wf(mapping_hash = nil, &block)
    chain(mapping_hash, &block)
  end

  def on_dam(&block)
    ::Waterfall::OnDam
      .new(self)
      .call(&block)
    self
  end

  def dam(obj)
    @error_pool = obj
    self
  end

  def undam
    dam nil
    self
  end

  def dammed?
    !error_pool.nil?
  end

  def is_waterfall?
    true
  end

  def flowing?
    !! @flowing
  end

  def update_outflow(key, value)
    @outflow[key] = value
    self
  end

  def _wf_run(&block)
    @flowing = true
    @outflow ||= OpenStruct.new({})
    yield unless dammed?
    self
  end

end

class Wf
  include Waterfall
  def initialize
    @outflow = OpenStruct.new({})
  end
end
