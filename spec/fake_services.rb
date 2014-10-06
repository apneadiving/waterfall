class Service
  def initialize(stuff)
    @thing = stuff
  end
  def call
    @thing[:service] = true
    @thing
  end
end

class ErrorService
  include Waterfall
  def call
    reject('ErrorService')
    nil
  end
end

class Service2
  include Waterfall
  def call(thing)
    thing[:service2] = true
    thing
  end
end

class Service3
  include Waterfall
  def call(thing)
    thing[:service3] = true
    thing
  end
end

class SubWf
  include Waterfall
  def initialize(h)
    @hash = h
  end

  def call
    self
      .then(:sub1)
      .then(:sub2)
  end

  def sub1
    @hash[:sub1] = true
  end

  def sub2
    @hash[:sub2] = true
  end
end

class SubWfErr
  include Waterfall
  def initialize(h)
    @hash = h
  end

  def call
    self
      .then(:sub1)
      .then(:sub2)
  end

  def sub1
    reject 'sub1'
  end

  def sub2
    @hash[:sub2] = true
  end
end

class SubWfWithNilErrors
  include Waterfall
  def call
    self
      .when_falsy(:foo, 'foo is missing')
  end

  def foo
    false
  end
end
