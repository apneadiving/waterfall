require 'spec_helper'

describe Flow do
  let(:wf) { Flow.new }

  it 'is aliased' do
    expect(Flow).to eq Wf
  end

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

  it 'returns itself to enable chaining' do
    expect(wf.chain{ }).to eq wf
    expect(wf.on_dam{ }).to eq wf
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

  it 'dam raises if falsy argument sent' do
    expect { wf.dam(nil) }.to raise_error(Waterfall::IncorrectDamArgumentError)
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

  it 'raises if chain waterfall without hash mapping' do
    expect { wf.chain(:foo) { Flow.new } }.to raise_error(Waterfall::IncorrectChainingArgumentError, Waterfall::Chain::MAPPING_ERROR_MESSAGE)
  end

  describe 'halt_chain' do
    it "yields expected values" do
      wf.chain(:foo) { 1 }.halt_chain do |outflow, error_pool|
        expect(outflow).to    eq wf.outflow
        expect(error_pool).to eq wf.error_pool
      end
    end

    it "yields expected values even if dammed" do
      wf.chain(:foo) { 1 }.dam("errr").halt_chain do |outflow, error_pool|
        expect(outflow).to    eq wf.outflow
        expect(error_pool).to eq wf.error_pool
      end
    end

    it "returns what the block returns" do
      expect(wf.halt_chain { "return value" }).to eq "return value"
    end
  end

  describe 'wrap_error_pool' do
    let(:error) { "Errrr" }

    ThrowAwayStruct = Struct.new(:err)

    let(:throw_away_patched_wf) do
      Class.new do
        include Waterfall

        def wrap_error_pool(obj)
          ThrowAwayStruct.new(obj)
        end
      end
    end

    it "does not wrap errors inside an object by default" do
      wf.dam(error)
      expect(wf.error_pool).to eq error
    end

    it "does wrap errors inside an object when told to" do
      flow = throw_away_patched_wf.new
      flow.dam(error)
      expect(flow.error_pool).to     be_a ThrowAwayStruct
      expect(flow.error_pool.err).to eq   error
    end
  end
end
