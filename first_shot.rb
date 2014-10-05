
require 'rubygems'
require 'active_model'
require 'pry'
module WaterFall

  attr_reader :waterfall_result

  class Base
    attr_reader :root, :args, :block, :handler
    def initialize(root, args, &block)
      @root, @args, @block = root, args, block
      @handler = get_handler
    end

    def trigger_handler(previous_output)
      if pass_arg?
        handler.call(previous_output)
      else
        handler.call
      end
    end

    def pass_arg?
      if handler.respond_to? :arity
        handler.arity == 1
      else
        handler.method(:call).arity == 1
      end
    end

    def get_handler
      return block if block
      first_arg_as_method_name? ? root.method(args[0]) : args[0]
    end

    def first_arg_as_method_name?
      args[0].is_a?(Symbol) || args[0].is_a?(String)
    end
  end

  class Then < Base
    attr_reader :output
    # .then(proc)
    # .then block
    # .then(method_name, error_text)
    # .then(method_name, error_text, error_key)
    def call(previous_output)
      @output = trigger_handler(previous_output)
      post_process
      output
    end

    def post_process
      if is_waterfall? && handler.stop_waterfall?
        handler.errors.each do |key, value|
          root.step_failed key, value
        end
      end
      if root._step_fails_on_falsy? && !output
        root.step_failed error_key, error_value
      end
    end

    def error_key
      if first_arg_as_method_name?
        args[2] || args[0]
      else
        args[2] || 'base'
      end
    end

    def error_value
      args[1] || 'invalid'
    end

    def is_waterfall?
      handler.respond_to?(:is_waterfall?) && handler.is_waterfall?
    end
  end

  class Catch < Base
    def call
      if root.stop_waterfall?
        trigger_handler(root.errors)
      else
        root.waterfall_result
      end
    end
  end

  def self.included(base)
    base.send :include, ::ActiveModel::Validations
  end

  def then(*args, &block)
    return self if stop_waterfall?

    @waterfall_result = Then
                          .new(self, args, &block)
                          .call(waterfall_result)

    self
  end

  def tap(proc = nil, &block)
    (proc || block).call self
  end

  def catch(*args, &block)
    Catch.new(self, args, &block).call
  end

  def step_failed(key, value)
    errors.add(key, value)
  end

  def stop_waterfall?
    errors.any?
  end

  def is_waterfall?
    true
  end

  def _step_fails_on_falsy?
    true
  end
end

class Wf
  include WaterFall
  attr_reader :options
  def initialize(options = {})
    @options = options.merge _default_options
  end

  def _step_fails_on_falsy?
    options[:step_failed_on_falsy]
  end

  def _default_options
    {
      step_failed_on_falsy: true
    }
  end
end

class Service
  def initialize(stuff)
    @thing = stuff
  end
  def call
    @thing[:service] = true
    @thing
  end
end

class ErrorService
  include WaterFall
  def call
    step_failed('ErrorService', 'error')
    nil
  end
end

class Service2
  include WaterFall
  def call(thing)
    thing[:service2] = true
    thing
  end
end

class Service3
  include WaterFall
  def call(thing)
    thing[:service3] = true
    thing
  end
end

class SubWf
  include WaterFall
  def initialize(h)
    @hash = h
  end

  def call
    self
      .then(:sub1)
      .then(:sub2)
  end

  def sub1
    @hash[:sub1] = true
  end

  def sub2
    @hash[:sub2] = true
  end
end

class SubWfErr
  include WaterFall
  def initialize(h)
    @hash = h
  end

  def call
    self
      .then(:sub1)
      .then(:sub2)
  end

  def sub1
    step_failed 'sub1', 'error'
  end

  def sub2
    @hash[:sub2] = true
  end
end

class SubWfWithNilErrors
  include WaterFall
  def call
    self
      .then(:foo, 'foo is missing')
  end

  def foo
    false
  end
end

class SubWfWithNilErrorsWithKey
  include WaterFall
  def call
    self
      .then(:foo, 'foo is missing', 'bar')
  end

  def foo
    nil
  end
end

describe 'Wf' do
  let(:dummy) { { } }
  it 'chain instructions, no error' do
    Wf.new
      .then(->{ dummy[:yo] = true })
      .then(Service.new(dummy))
      .then(Service2.new)
      .then(Service3.new)
      .then(->(du){ du[:bash] = true })
      .catch(->{ dummy[:error] = true })

    expect(dummy[:yo]).to be_true
    expect(dummy[:service]).to be_true
    expect(dummy[:service2]).to be_true
    expect(dummy[:service3]).to be_true
    expect(dummy[:bash]).to be_true
    expect(dummy[:error]).to_not be_true
  end

  it 'chain instructions, no error' do
    Wf.new
      .then do
        dummy[:yo] = true
      end
      .then(Service.new(dummy))
      .then(Service2.new)
      .then(Service3.new)
      .then do |du|
        du[:bash] = true
      end
      .catch do
        dummy[:error] = true
      end

    expect(dummy[:yo]).to be_true
    expect(dummy[:service]).to be_true
    expect(dummy[:service2]).to be_true
    expect(dummy[:service3]).to be_true
    expect(dummy[:bash]).to be_true
    expect(dummy[:error]).to_not be_true
  end

  it 'works' do
    Wf.new
      .then(ErrorService.new)
      .catch(->(error){ dummy[:error] = error })
    expect(dummy[:error]).to include(:ErrorService)
  end

  it 'works' do
    Wf.new
      .tap(->(s){ @sery = s })
      .then(->{ dummy[:yo] = true })
      .then(Service.new(dummy))
      .then(->{ @sery.step_failed('inside', 'error') })
      .then(Service2.new)
      .then(Service3.new)
      .then(->{ dummy[:bash] = true })
      .catch do |error|
        dummy[:error] = error
      end

    expect(dummy[:yo]).to be_true
    expect(dummy[:service]).to be_true
    expect(dummy[:service2]).to_not be_true
    expect(dummy[:service3]).to_not be_true
    expect(dummy[:bash]).to_not be_true
    expect(dummy[:error]).to include(:inside)
  end

  it 'with subsery' do
    Wf.new
      .then(SubWf.new(dummy))

    expect(dummy[:sub1]).to be_true
    expect(dummy[:sub2]).to be_true
  end

  it 'with subsery and error' do
    Wf.new
      .then(SubWfErr.new(dummy))
      .catch do |error|
        dummy[:error] = error
      end

    expect(dummy[:sub2]).to_not be_true
    expect(dummy[:error]).to include :sub1
  end

  it 'with explicit nil errors' do
    Wf.new
      .then(SubWfWithNilErrors.new)
      .catch do |error|
        dummy[:error] = error
      end
    expect(dummy[:error]).to include :foo
  end

  it 'with explicit nil errors' do
    Wf.new
      .then(SubWfWithNilErrorsWithKey.new)
      .then(->{ dummy[:foo] = true })
      .catch do |error|
        dummy[:error] = error
      end
    expect(dummy[:error]).to include :bar
    expect(dummy[:foo]).to_not be_true
  end
end
