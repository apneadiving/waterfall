require 'spec_helper'

describe 'Chaining services' do

  let(:service_class) do
    Class.new do
      include Waterfall
      def initialize(options = {})
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
        self
      end
    end
  end

  let(:wf) { Flow.new }
  let(:listener) { spy 'listener', is_waterfall?: false }

  it 'you dont need to call child waterfalls, just pass the instance' do
    service = service_class.new
    expect(service.has_flown?).to be false
    wf.chain { service }
    expect(service.has_flown?).to be true
  end

  context 'child executed without damming' do
    it 'passes data from one outflow to the other' do
      wf
        .chain(local_foo: :foo, local_bar: :bar) { service_class.new }
        .chain  { listener.success }
        .on_dam { listener.failure }

      expect(wf.outflow.local_foo).to eq 'foo_value'
      expect(wf.outflow.local_bar).to eq 'bar_value'
      expect(wf.dammed?).to be false
      expect(wf.error_pool).to eq nil
      expect(listener).to have_received :success
    end

    it 'passes only required data from one outflow to the other' do
      wf
        .chain(local_foo: :foo) { service_class.new }
        .chain  { listener.success }
        .on_dam { listener.failure }

      expect(wf.outflow.local_foo).to eq 'foo_value'
      expect(wf.outflow.local_bar).to eq nil
      expect(listener).to have_received :success
    end
  end

  context 'child dams on when_falsy' do
    it 'stops on dam yet passes existing data' do
      wf
        .chain(local_foo: :foo, local_bar: :bar) { service_class.new(falsy_check: false) }
        .chain  { listener.success }
        .on_dam { listener.failure }

      expect(wf.outflow.local_foo).to eq nil
      expect(wf.outflow.local_bar).to eq nil
      expect(wf.dammed?).to be true
      expect(wf.error_pool).to eq 'errr1'
      expect(listener).to have_received :failure
    end
  end

  context 'dammed on when_truthy statement' do
    it 'stops on dam yet passes existing data' do
      wf
        .chain(local_foo: :foo, local_bar: :bar) { service_class.new(truthy_check: true) }
        .chain  { listener.success }
        .on_dam { listener.failure }

      expect(wf.outflow.local_foo).to eq 'foo_value'
      expect(wf.outflow.local_bar).to eq nil
      expect(wf.dammed?).to be true
      expect(wf.error_pool).to eq 'errr2'
      expect(listener).to have_received :failure
    end
  end
end
