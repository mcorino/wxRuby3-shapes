# Wx::SF::SolidArrow - solid arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrow_base'

module Wx::SF

  class SolidArrow < ArrowBase

    class << self
      def solid_arrow
        @solid_arrow ||= [Wx::RealPoint.new(0,0), Wx::RealPoint.new(10,4), Wx::RealPoint.new(10,-4)]
      end
    end

    property :arrow_fill, :arrow_pen

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super
      @fill = DEFAULT.fill
      @pen = DEFAULT.border
    end

    # Get arrow fill brush
    # @return [Wx::Brush]
    def get_arrow_fill
      @fill
    end
    alias :arrow_fill :get_arrow_fill
    
    # Set arrow fill brush
    # @param [Wx::Brush] brush
    def set_arrow_fill(brush)
      @fill = brush
    end
    alias :arrow_fill= :set_arrow_fill

    # Get arrow border pen
    # @return [Wx::Pen]
    def get_arrow_pen
      @pen
    end
    alias :arrow_pen :get_arrow_pen

    # Set arrow border pen
    # @param [Wx::Pen] pen
    def set_arrow_pen(pen)
      @pen = pen
    end
    alias :arrow_pen= :set_arrow_pen

	  # Draw arrow shape at the end of a virtual line.
	  # @param [Wx::RealPoint] from Start of the virtual line
	  # @param [Wx::RealPoint] to End of the virtual line
	  # @param [Wx::DC] dc Device context for drawing
    def draw(from, to, dc)
      rarrow = translate_arrow(SolidArrow.solid_arrow, from, to)
      dc.with_pen(@pen) do |dc|
        dc.with_brush(@fill) do |dc|
          dc.draw_polygon(rarrow)
        end
      end
    end

  end

end
