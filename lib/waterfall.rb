require 'ostruct'
require 'waterfall/version'
require 'waterfall/predicates/base'
require 'waterfall/predicates/on_dam'
require 'waterfall/predicates/when_falsy'
require 'waterfall/predicates/when_truthy'
require 'waterfall/predicates/chain'

WATERFALL_PATH = "lib/waterfall.rb"

module Waterfall

  attr_reader :error_pool, :error_pool_context

  class IncorrectDamArgumentError      < StandardError; end
  class IncorrectChainingArgumentError < StandardError; end

  class << self
    attr_accessor :with_reversible_flow
    attr_accessor :caller_locations_length
  end
  @with_reversible_flow = true
  @caller_locations_length = nil

  def outflow
    @outflow ||= OpenStruct.new({})
  end

  def when_falsy(&block)
    ::Waterfall::WhenFalsy.new(self).tap do |handler|
      _wf_run { handler.call(&block) }
    end
  end

  def when_truthy(&block)
    ::Waterfall::WhenTruthy.new(self).tap do |handler|
      _wf_run { handler.call(&block) }
    end
  end

  def chain(mapping_or_var_name = nil, &block)
    _wf_run do
      ::Waterfall::Chain
        .new(self, mapping_or_var_name)
        .call(&block)
    end
  end

  def on_dam(&block)
    ::Waterfall::OnDam
      .new(self)
      .call(&block)
    self
  end

  def dam(obj, context = nil)
    raise IncorrectDamArgumentError.new("You cant dam with a falsy object") unless obj
    _wf_run do
      @error_pool = obj
      @error_pool_context = context || _error_pool_context
      _reverse_flows(true)
    end
  end

  def halt_chain(&block)
    yield(outflow, error_pool, error_pool_context)
  end

  def dammed?
    !error_pool.nil?
  end

  def is_waterfall?
    true
  end

  def has_flown?
    !! @has_flown
  end

  def update_outflow(key, value)
    @outflow[key] = value
    self
  end

  def reverse_flow
  end

  protected

  def _reverse_flows(skip_self)
    return unless Waterfall.with_reversible_flow
    return if @flow_reversed
    @flow_reversed = true
    reverse_flow unless skip_self
    (@_executed_flows || []).reverse_each do |f|
      f.send :_reverse_flows, false
    end
  end

  def _add_executed_flow(flow)
    return unless Waterfall.with_reversible_flow
    @_executed_flows ||= []
    @_executed_flows.push(flow)
  end

  def _wf_run
    @has_flown = true
    yield unless dammed?
    self
  end

  def _error_pool_context
    caller_locations(1, Waterfall.caller_locations_length).reject do |line|
      line.to_s.include?(WATERFALL_PATH)
    end
  end
end

class Wf
  include Waterfall
  def initialize
    _wf_run {}
  end
end

Flow = Wf
