require 'spec_helper'

describe Wf do
  let(:wf) { Wf.new }

  it 'is a waterfall' do
    expect(wf.is_waterfall?).to be true
  end

  it 'and a waterfall flows when called' do
    expect(wf.has_flown?).to be true
  end

  it 'executes code in chain block' do
    listener = double 'listener'
    expect(listener).to receive :success

    wf.chain { listener.success }
  end

  it 'executes code in chain block and store it in outflow upon request' do
    wf.chain(:foo) { 1 }
    expect(wf.outflow.foo).to eq 1
  end

  it 'chain yields outflow and waterfall itself' do
    wf.chain do |outflow, waterfall|
      expect(outflow).to eq wf.outflow
      expect(waterfall).to eq wf
    end
  end

  it 'isnt dammed by default' do
    expect(wf.dammed?).to be false
    expect(wf.error_pool).to eq nil
  end

  it 'is dammed if you dam it!' do
    wf.dam('error')
    expect(wf.dammed?).to be true
    expect(wf.error_pool).to eq 'error'
  end

  it 'can be undammed' do
    wf.dam('error').undam
    expect(wf.dammed?).to be false
    expect(wf.error_pool).to eq nil
  end

  it 'can be dammed conditionnaly (falsy)' do
    wf.when_falsy { false }.dam { 'error' }
    expect(wf.dammed?).to be true
    expect(wf.error_pool).to eq 'error'
  end

  it 'can be dammed conditionnaly (truthy)' do
    wf.when_truthy { true }.dam { 'error' }
    expect(wf.dammed?).to be true
    expect(wf.error_pool).to eq 'error'
  end

  it 'doesnt execute chain blocks once dammed' do
    expect do
      wf.when_falsy { false }.dam { 'error' }.chain { raise 'I should not be executed because of damming before me' }
    end.to_not raise_error
  end

  it 'doesnt execute on_dam blocks when not dammed' do
    expect do
      wf.on_dam { raise 'I should not be executed because of damming before me' }
    end.to_not raise_error
  end

  it 'executes on_dam blocks once dammed' do
    listener = spy 'listener'
    wf.dam('errr').on_dam { listener.failure }

    expect(listener).to have_received :failure
  end

  it 'on_dam blocks yield error pool, outflow and waterfall' do
    wf.dam('errr').on_dam do |error_pool, outflow, waterfall|
      expect(error_pool).to eq wf.error_pool
      expect(outflow).to eq wf.outflow
      expect(waterfall).to eq wf
    end
  end
end
