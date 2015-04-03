require 'spec_helper'
require 'benchmark'

describe 'benchmark' do

  class FakeServiceBase
    include Waterfall
    def call
      self.chain { }
    end

    def rollback
    end
  end

  class MasterFakeService < FakeServiceBase
  end

  class FakeService1 < FakeServiceBase
    def call
      self
        .chain_wf { SubFakeService1.new }
        .chain { }
        .chain { }
    end
  end

  class FakeService2 < FakeServiceBase
  end

  class FakeService3 < FakeServiceBase
    def call
      self.chain {|outflow, wf| wf.dam 'error' }
    end
  end

  class FakeService4 < FakeServiceBase
  end

  class SubFakeService1 < FakeServiceBase
  end

  def action
    MasterFakeService.new
      .chain_wf { FakeService1.new }
      .chain_wf { FakeService2.new }
      .chain_wf { FakeService3.new }
      .chain_wf { FakeService4.new }
  end

  # it "benchmarks" do
  #   n = 500000
  #   Benchmark.bm do |x|
  #     x.report { n.times { action } }
  #   end
  # end
end
