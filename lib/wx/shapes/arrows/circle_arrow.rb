# Wx::SF::CircleArrow - circle arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/solid_arrow'

module Wx::SF

  class CircleArrow < SolidArrow

    # Default circle radius.
    RADIUS = 4

    property :radius

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super
      @radius = 4
    end

    # Get or set the circle radius
    attr_accessor :radius

    # Draw arrow shape at the end of a virtual line.
    # @param [Wx::RealPoint] from Start of the virtual line
    # @param [Wx::RealPoint] to End of the virtual line
    # @param [Wx::DC] dc Device context for drawing
    def draw(from, to, dc)
      rarrow = translate_arrow(DiamondArrow.diamond_arrow, from, to)
      dc.with_pen(@pen) do |dc|
        dc.with_brush(@fill) do |dc|
          dc.draw_circle(to.to_point, @radius)
        end
      end
    end

  end

end
