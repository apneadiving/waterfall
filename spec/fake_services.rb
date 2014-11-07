class SubWfWithNilErrors
  include Waterfall
  def call
    self
      .when_falsy { foo }.reject { 'foo is missing' }
  end

  def foo
    false
  end
end

class ChainExample
  include Waterfall

  def call
    self
      .chain(:result1) { result1 }
      .chain_wf({ result2: :hello }) { result2 }
      .chain(:result3) {  result3 }
      .chain { |wf_response| wf_response[:result4] = 4 }
  end

  def result1
    1
  end

  def result2
    ChainExampleInsider.new
  end

  def result3
    3
  end
end

class ChainExampleInsider
  include Waterfall

  def call
    self
      .chain(:hello) { hi }
  end

  def hi
    'hi'
  end

end

class InterruptedChain
  include Waterfall
  def call
    self
      .chain(:result1) { result1 }
      .chain_wf({ result2: :hello1 }) { result2 }
      .chain(:result3) { result3 }
      .chain { |wf_response| wf_response[:result4] = 4 }
  end

  def result1
    1
  end

  def result2
    ChainExampleInterruptor.new
  end

  def result3
    3
  end
end

class ChainExampleInterruptor
  include Waterfall

  def call
    self
      .chain(:hello) { hi }
  end

  def hi
    reject 'no!'
  end

end
