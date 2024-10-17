# Wx::SF::CrossBarCircleArrow - crossbar with circle arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/circle_arrow'

module Wx::SF

  # Class extends the Wx::CircleArrow class and encapsulates
  # circle arrow shapes with a crossbar.
  class CrossBarCircleArrow < CircleArrow

    class << self
      def arrow(ratio)
        x = ratio*6; y = ratio*6
        [Wx::RealPoint.new(x,y), Wx::RealPoint.new(x, -y), Wx::RealPoint.new(x, 0)]
      end
    end

    # Default circle radius.
    RADIUS = 4

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super
      scale
    end

    def line
      @line ||= CrossBarCircleArrow.arrow(@ratio)
    end
    private :line

    def scale
      @line = nil
      super
    end
    protected :scale

    # Draw arrow shape at the end of a virtual line.
    # @param [Wx::RealPoint] from Start of the virtual line
    # @param [Wx::RealPoint] to End of the virtual line
    # @param [Wx::DC] dc Device context for drawing
    def draw(from, to, dc)
      dc.with_pen(pen) do |dc|
        bar_from, bar_to, bar_mid = translate_arrow(line, from, to)
        dc.draw_line(bar_from, bar_to)
        dc.draw_line(bar_mid, to.to_point)
        to = bar_mid
      end
      super(from, to, dc)
    end

  end

end
