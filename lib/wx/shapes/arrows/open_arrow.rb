# Wx::SF::OpenArrow - open arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrow_base'

module Wx::SF

  # Class extends the wxSFArrowBase class and encapsulates
  # arrow shape consisting of single two lines leading from the end of the
  # parent line shape.
  class OpenArrow < ArrowBase

    class << self
      def open_arrow
        @open_arrow ||= [Wx::RealPoint.new(0,0), Wx::RealPoint.new(10,4), Wx::RealPoint.new(10,-4)]
      end
    end

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
      rarrow = translate_arrow(OpenArrow.open_arrow, from, to)
      dc.with_pen(@pen) do |dc|
        dc.draw_line(rarrow[0], rarrow[1])
        dc.draw_line(rarrow[0], rarrow[2])
      end
    end

  end

end
