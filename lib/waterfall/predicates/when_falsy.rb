require_relative 'when_truthy'

module Waterfall
  class WhenFalsy < WhenTruthy

    def condition?
      ! super
    end
  end
end
