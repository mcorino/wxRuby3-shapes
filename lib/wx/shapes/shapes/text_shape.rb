# Wx::SF::TextShape - text shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'

module Wx::SF

  class TextShape < RectShape

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, diagram)
    #   User constructor.
    #   @param [Wx::Point] pos Initial position
    #   @param [Wx::Size] size Initial size
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)

    end

  end

end
