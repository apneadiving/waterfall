require_relative 'when_truthy'

module Waterfall
  class WhenFalsy < WhenTruthy

    def dammed?
      !super
    end

  end
end
