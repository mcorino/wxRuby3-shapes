# Wx::SF::CircleArrow - circle arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/filled_arrow'

module Wx::SF

  # Class extends the Wx::FilledArrow class and encapsulates
  # circle arrow shapes.
  class CircleArrow < FilledArrow

    # Default circle radius.
    RADIUS = 6

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

    def scale
      @ratio = 1 + (pen_width / 2) * 0.5
    end
    protected :scale

    # Draw arrow shape at the end of a virtual line.
    # @param [Wx::RealPoint] from Start of the virtual line
    # @param [Wx::RealPoint] to End of the virtual line
    # @param [Wx::DC] dc Device context for drawing
    def draw(from, to, dc)
      r = radius
      centre, cp = translate_arrow([Wx::RealPoint.new(r, 0), Wx::RealPoint.new(2*r, 0)], from, to)
      dc.with_pen(pen) do |dc|
        dc.with_brush(fill) do |dc|
          dc.draw_circle(centre, r)
        end
      end
      cp
    end

  end

end
