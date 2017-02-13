require 'spec_helper'

describe 'Service' do

  let(:service_class) do
    Class.new do
      include Waterfall
      attr_reader :error

      def initialize(options)
        @options = {
          falsy_check:  true,
          truthy_check: false
        }.merge options
      end

      def call
        when_falsy { @options[:falsy_check] }
          .dam { 'errr1' }
        chain(:foo) { 'foo_value' }
        when_truthy { @options[:truthy_check] }
          .dam { 'errr2' }
        chain(:bar) { 'bar_value' }
      end
    end
  end

  let(:service) { service_class.new(options).tap(&:call) }

  it 'a waterfall doesnt flow until one chain is executed' do
    expect(service_class.new({}).has_flown?).to be false
  end

  context 'default options' do
    let(:options) {{}}

    it 'has flown whenever one chain has been executed' do
      expect(service.has_flown?).to be true
    end

    it 'executes without damming' do
      expect(service.outflow.foo).to eq 'foo_value'
      expect(service.outflow.bar).to eq 'bar_value'
      expect(service.dammed?).to be false
      expect(service.error_pool).to eq nil
    end
  end

  context 'dammed on when_falsy statement' do
    let(:options) {{ falsy_check: false }}
    it 'stops on dam' do
      expect(service.outflow.foo).to eq nil
      expect(service.outflow.bar).to eq nil
      expect(service.dammed?).to be true
      expect(service.error_pool).to eq 'errr1'
    end
  end

  context 'dammed on when_truthy statement' do
    let(:options) {{ truthy_check: true }}
    it 'stops on dam' do
      expect(service.outflow.foo).to eq 'foo_value'
      expect(service.outflow.bar).to eq nil
      expect(service.dammed?).to be true
      expect(service.error_pool).to eq 'errr2'
    end
  end

  let(:service_class2) do
    Class.new do
      include Waterfall

      def initialize(listener, options)
        @to_dam, @listener = options[:to_dam], listener
      end

      def call
        dam('error') if @to_dam
        chain  { @listener.success }
        on_dam { @listener.failure }
      end
    end
  end

  let(:listener) { spy 'listener', is_waterfall?: false }

  it 'sends success message to listener' do
    service_class2.new(listener, to_dam: false).call

    expect(listener).to have_received(:success)
  end

  it 'sends failure message to listener' do
    service_class2.new(listener, to_dam: true).call

    expect(listener).to have_received(:failure)
  end
end
