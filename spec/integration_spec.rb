require 'spec_helper'

describe 'Wf' do
  let(:dummy) { { } }

  it "gives access to wf outflow" do
    wf = Wf.new
      .chain(:foo) { 'foo' }
      .chain  {|outflow| outflow[:bar] = 'bar' }
      .on_dam {|error_pool| dummy[:errors] = error_pool }
    expect(wf.outflow[:foo]).to eq 'foo'
    expect(wf.outflow[:bar]).to eq 'bar'
    expect(dummy[:errors]).to be_nil
  end

  it "gives access to wf internals" do
    wf = Wf.new
      .chain(:foo) { 'foo' }
      .chain  {|outflow, wf| wf.dam('errrrr') }
      .on_dam {|error_pool| dummy[:errors] = error_pool }

    expect(wf.outflow[:foo]).to eq 'foo'
    expect(wf.dammed?).to be true
    expect(dummy[:errors]).to_not be_nil
  end

  it 'with explicit nil errors' do
    Wf.new
      .chain_wf { SubWfWithNilErrors.new }
      .on_dam do |error|
        dummy[:error] = error
      end
    expect(dummy[:error]).to eq 'foo is missing'
  end

  context "chain" do
    it "returns expected result" do
      Wf.new
        .merge_wf { ChainExample.new }
        .chain {|result| dummy[:result] = result }

      expected = {
        result1: 1,
        result2: 'hi',
        result3: 3,
        result4: 4
      }

      expect(dummy[:result]).to eq expected
    end

    it "interruption" do
      Wf.new
        .merge_wf { InterruptedChain.new }
        .chain  {|result| dummy[:result] = result }
        .on_dam {|errors| dummy[:errors] = errors }

      expect(dummy).to_not have_key :result
      expect(dummy[:errors]).to eq 'no!'
    end

    it "a raw wf should not be called again" do
      wf = InterruptedChain.new
      expect(wf).to receive(:call).once.and_call_original

      Wf.new
        .merge_wf { wf.call }
    end
  end

  context "when falsy" do
    def action(bool)
      Wf.new
        .when_falsy { bool }
          .dam  { 'err' }
        .chain  { @foo = 1 }
        .on_dam { |error_pool| @error = error_pool }
    end

    it "when actually falsy" do
      action false
      expect(@error).to eq 'err'
      expect(@foo).to_not eq 1
    end

    it "when actually truthy" do
      action true
      expect(@error).to_not eq 'err'
      expect(@foo).to eq 1
    end
  end

end
