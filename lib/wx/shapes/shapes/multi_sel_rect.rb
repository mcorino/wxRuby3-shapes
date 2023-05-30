# Wx::SF::MultiSelRect - multi-sel rect shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'

module Wx::SF

  class MultiSelRect < RectShape

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, diagram)
    #   User constructor.
    #   @param [Wx::Point] pos Initial position
    #   @param [Wx::Size] size Initial size
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize
      super
    end

  end

end
