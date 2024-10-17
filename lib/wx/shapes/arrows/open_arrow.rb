# Wx::SF::OpenArrow - open arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/line_arrow'

module Wx::SF

  # Class extends the Wx::LineArrow class and encapsulates
  # arrow shape consisting of single two lines leading from the end of the
  # parent line shape.
  class OpenArrow < LineArrow

    class << self
      def arrow(ratio)
        x = ratio*11; y = ratio*5
        [Wx::RealPoint.new(0,0), Wx::RealPoint.new(x, y), Wx::RealPoint.new(x,-y), Wx::RealPoint.new(x, 0)]
      end
    end

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super(parent)
      scale
    end

    def vertices
      @vertices ||= OpenArrow.arrow(@ratio)
    end
    private :vertices

    def scale
      @vertices = nil
      @ratio = 1 + (pen_width / 2) * 0.5
    end
    protected :scale

	  # Draw arrow shape at the end of a virtual line.
	  # @param [Wx::RealPoint] from Start of the virtual line
	  # @param [Wx::RealPoint] to End of the virtual line
	  # @param [Wx::DC] dc Device context for drawing
    # @return [Wx::Point] translated connection point for arrow
    def draw(from, to, dc)
      tip, wing1, wing2, cp = translate_arrow(vertices, from, to)
      dc.with_pen(pen) do |dc|
        dc.draw_line(tip, wing1)
        dc.draw_line(tip, wing2)
        dc.draw_line(tip, cp)
      end
      cp
    end

  end

end
