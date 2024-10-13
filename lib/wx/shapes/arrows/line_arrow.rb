# Wx::SF::LineArrow - line drawn arrow base class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrow_base'

module Wx::SF

  # Class extends the Wx::ArrowBase class and encapsulates
  # line drawn arrow shapes.
  # The shapes are automatically scaled based on the line width used.
  class LineArrow < ArrowBase

    property pen: :serialize_pen

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super
      @pen = nil
    end

    # Get arrow border pen
    # @return [Wx::Pen,nil]
    def get_pen
      @pen || @parent_shape&.line_pen
    end
    alias :pen :get_pen

    # Set arrow border pen (when nil restore the default).
    # @param [Wx::Pen,nil] pen
    def set_pen(pen)
      @pen = pen
      scale
    end
    alias :pen= :set_pen

    # Return current pen width.
    # @return [Integer]
    def get_pen_width
      get_pen&.width || 1
    end
    alias :pen_width :get_pen_width

    # Set a parent of the arrow shape.
    # @param [Wx::SF::Shape] parent parent shape
    def set_parent_shape(parent)
      super
      scale
    end
    alias :parent_shape= :set_parent_shape

    # Scale the arrow.
    # Does nothing by default.
    def scale
      # noop
    end
    protected :scale

    def serialize_pen(*arg)
      @pen = arg.shift unless arg.empty?
      @pen
    end
    private :serialize_pen

  end

end
