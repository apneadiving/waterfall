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

  describe 'reverse_flow' do
    let(:parent_flow) { Flow.new }
    let(:sub_flow1)   { Flow.new }
    let(:sub_flow2)   { Flow.new }
    let(:sub_flow3)   { Flow.new }
    let(:sub_sub_flow1) { Flow.new }
    let(:sub_sub_flow2) { Flow.new }
    let(:sub_sub_flow3) { Flow.new }
    let(:sub_sub_sub_flow1) { Flow.new }

    def action
      parent_flow
        .chain { sub_flow1 }
        .chain do
          sub_flow2
            .chain do
              sub_sub_flow1.chain { sub_sub_sub_flow1 }
            end
            .chain { sub_sub_flow2 }
            .when_truthy { true }.dam { 'errr' }
            .chain { sub_sub_flow3 }
        end
        .chain { sub_flow3 }
    end

    it 'does not trigger reverse_flow on initial dammed flow' do
      expect(sub_flow2).to_not receive(:reverse_flow)

      action
    end

    it 'does not trigger reverse_flow on parent_flow' do
      expect(parent_flow).to_not receive(:reverse_flow)

      action
    end

    it 'is called on all executed sub flows' do
      expect(sub_sub_flow2).to receive(:reverse_flow).once.ordered
      expect(sub_sub_flow1).to receive(:reverse_flow).once.ordered
      expect(sub_sub_sub_flow1).to receive(:reverse_flow).once.ordered
      expect(sub_flow1).to receive(:reverse_flow).once.ordered

      action
    end

    it 'is not called on non executed sub flows' do
      expect(sub_sub_flow3).to_not receive(:reverse_flow)
      expect(sub_flow3).to_not receive(:reverse_flow)

      action
    end

    context "without reversible flow" do
      around do |example|
        Waterfall.with_reversible_flow = false
        example.run
        Waterfall.with_reversible_flow = true
      end

      it 'doesnt call reverse_flow, ever' do
        expect(sub_sub_flow2).to_not receive(:reverse_flow)
        expect(sub_sub_flow1).to_not receive(:reverse_flow)
        expect(sub_sub_sub_flow1).to_not receive(:reverse_flow)
        expect(sub_flow1).to_not receive(:reverse_flow)

        action
      end
    end
  end
end
