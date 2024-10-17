# Wx::SF::SquareArrow - square arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/line_arrow'

module Wx::SF

  # Class extends the Wx::SolidArrow class and encapsulates
  # cup arrow shapes.
  class CupArrow < LineArrow

    # Default arc radius size
    RADIUS = 7

    class << self

      def arrow(radius)
        [Wx::RealPoint.new(0, radius), Wx::RealPoint.new(0, -radius), Wx::RealPoint.new(0, 0), Wx::RealPoint.new(radius, 0)]
      end

    end

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super
      scale
    end

    # Get the circle radius
    def get_radius
      (RADIUS * @ratio).to_i
    end
    alias :radius :get_radius

    def coords
      @coords ||= CupArrow.arrow(get_radius)
    end
    protected :coords

    def scale
      @coords = nil
      @ratio = 1 + (pen_width / 2) * 0.5
    end
    protected :scale

    # Draw arrow shape at the end of a virtual line.
    # @param [Wx::RealPoint] from Start of the virtual line
    # @param [Wx::RealPoint] to End of the virtual line
    # @param [Wx::DC] dc Device context for drawing
    # @return [Wx::Point] translated connection point for arrow
    def draw(from, to, dc)
      rarrow = translate_arrow(coords, from, to)
      cp = rarrow.pop
      dc.with_pen(pen) do |dc|
        dc.with_brush(Wx::TRANSPARENT_BRUSH) do |dc|
          dc.draw_arc(*rarrow)
        end
      end
      cp
    end

  end

end
