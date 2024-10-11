# Wx::SF::LineArrow - line drawn arrow base class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrow_base'

module Wx::SF

  # Class extends the Wx::ArrowBase class and encapsulates
  # line drawn arrow shapes.
  # The shapes are automatically scaled based on the line width used.
  class LineArrow < ArrowBase

    property :arrow_pen

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super
      @pen = DEFAULT.border
    end

    # Get arrow border pen
    # @return [Wx::Pen]
    def get_arrow_pen
      @pen
    end
    alias :arrow_pen :get_arrow_pen

    # Set arrow border pen (when nil restore the default).
    # @param [Wx::Pen,nil] pen
    def set_arrow_pen(pen)
      @pen = pen || DEFAULT.border
      scale
    end
    alias :arrow_pen= :set_arrow_pen

    # Scale the arrow.
    # Does nothing by default.
    def scale
      # noop
    end
    protected :scale

  end

end
