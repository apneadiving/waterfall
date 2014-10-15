require 'spec_helper'

describe 'Wf' do
  let(:dummy) { { } }
  it 'with explicit nil errors' do
    Wf.new
      .chain_wf { SubWfWithNilErrors.new }
      .catch do |error|
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
        .chain {|result| dummy[:result] = result }
        .catch {|errors| dummy[:errors] = errors }

      expect(dummy[:result]).to be_nil
      expect(dummy[:errors]).to eq 'no!'
    end
  end

end
