require 'spec_helper'

describe 'promises inheritance' do
  let(:wf) { Wf.new }

  class PromiseService1
    include Waterfall
    promises :foo, :bar
  end

  class PromiseService2 < PromiseService1
    promises :baz
  end

  it "saves promises" do
    expect(PromiseService1._wf_promises).to eq [:foo, :bar]
  end

  it "saves promises" do
    expect(PromiseService1._wf_promises).to eq [:foo, :bar]
    expect(PromiseService2._wf_promises).to eq [:foo, :bar, :baz]
  end

  after(:all) do
    Object.send(:remove_const, :PromiseService1)
    Object.send(:remove_const, :PromiseService2)
  end
end

describe 'promises check' do
  let(:wf) { Wf.new }

  class PromiseServiceError1
    include Waterfall
    promises :foo, :bar

    def call
      ensure_promises do
      end
    end
  end

  it "fails and requires :foo and :bar" do
    expect {
      PromiseServiceError1.new.call
    }.to raise_error(::Waterfall::PromiseMissing)
  end

  class PromiseServiceError2
    include Waterfall
    promises :foo, :bar

    def call
      ensure_promises do
        self.chain(:foo){ 1 }
      end
    end
  end

  it "fails and requires :bar" do
    expect {
      PromiseServiceError2.new.call
    }.to raise_error(::Waterfall::PromiseMissing)
  end

  class PromiseServiceError3
    include Waterfall
    promises :foo, :bar

    def call
      ensure_promises do
        self.chain(:bar){ 1 }
      end
    end
  end

  it "fails and requires :foo" do
    expect {
      PromiseServiceError3.new.call
    }.to raise_error(::Waterfall::PromiseMissing)
  end

  class PromiseSuccess1
    include Waterfall
    promises :foo, :bar

    def call
    end
  end

  it "succeeds because no ensure_promises" do
    expect {
      PromiseSuccess1.new.call
    }.not_to raise_error
  end

  class PromiseSuccess2
    include Waterfall
    promises :foo, :bar

    def call
      ensure_promises do
        self.chain(:foo){ nil }.chain(:bar){ false }
      end
    end
  end

  it "succeeds because promises keys are present" do
    expect {
      PromiseSuccess2.new.call
    }.not_to raise_error
  end

  after(:all) do
    Object.send(:remove_const, :PromiseServiceError1)
    Object.send(:remove_const, :PromiseServiceError2)
    Object.send(:remove_const, :PromiseServiceError3)
    Object.send(:remove_const, :PromiseSuccess1)
    Object.send(:remove_const, :PromiseSuccess2)
  end
end
