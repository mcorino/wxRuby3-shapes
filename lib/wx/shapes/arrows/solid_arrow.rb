# Wx::SF::SolidArrow - solid arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/filled_arrow'

module Wx::SF

  # Class extends the Wx::FilledArrow class and encapsulates
  # solid arrow shapes.
  class SolidArrow < FilledArrow

    class << self
      def arrow(ratio)
        x = ratio*11; y = ratio*5
        [Wx::RealPoint.new(0,0), Wx::RealPoint.new(x, y), Wx::RealPoint.new(x,-y), Wx::RealPoint.new(x,0)]
      end
    end

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super
      scale
    end

    def vertices
      @vertices ||= SolidArrow.arrow(@ratio)
    end
    protected :vertices

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
      rarrow = translate_arrow(vertices, from, to)
      cp = rarrow.pop # get connection point
      dc.with_pen(pen) do |dc|
        dc.with_brush(@fill) do |dc|
          dc.draw_polygon(rarrow)
        end
      end
      cp
    end

  end

end
