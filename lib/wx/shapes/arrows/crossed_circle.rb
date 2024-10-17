# Wx::SF::CrossedCircleArrow - circle with cross arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/circle_arrow'

module Wx::SF

  # Class extends the Wx::CircleArrow class and encapsulates
  # arrow shape consisting a crossed circle.
  class CrossedCircleArrow < CircleArrow

    class << self
      def crossbar(radius)
        [Wx::RealPoint.new(radius,radius), Wx::RealPoint.new(radius, -radius)]
      end
    end

    def crossbar
      @crossbar ||= CrossedCircleArrow.crossbar(radius)
    end
    private :crossbar

    def scale
      @crossbar = nil
      super
    end
    protected :scale

    # Draw arrow shape at the end of a virtual line.
    # @param [Wx::RealPoint] from Start of the virtual line
    # @param [Wx::RealPoint] to End of the virtual line
    # @param [Wx::DC] dc Device context for drawing
    # @return [Wx::Point] translated connection point for arrow
    def draw(from, to, dc)
      cp = super
      cb = translate_arrow(crossbar, from, to)
      dc.with_pen(pen) do |dc|
        dc.draw_line(cb[0], cb[1])
        dc.draw_line(cp, to.to_point)
      end
      cp
    end

  end

end
