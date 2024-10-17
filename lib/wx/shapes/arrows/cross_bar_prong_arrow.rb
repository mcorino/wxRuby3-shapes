# Wx::SF::CrossBarProngArrow - crossbar with prong arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/prong_arrow'

module Wx::SF

  # Class extends the Wx::ProngArrow class and encapsulates
  # arrow shape consisting of single two lines bisecting before the end of the
  # parent line shape with a crossbar at the intersection point.
  class CrossBarProngArrow < ProngArrow

    class << self
      def arrow(ratio)
        x = ratio*6; y = ratio*6
        [Wx::RealPoint.new(0,y), Wx::RealPoint.new(0, -y), Wx::RealPoint.new(0, 0)]
      end
    end

    def line
      @line ||= CrossBarProngArrow.arrow(@ratio)
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
    # @return [Wx::Point] translated connection point for arrow
    def draw(from, to, dc)
      to = super
      dc.with_pen(pen) do |dc|
        bar_from, bar_to, bar_mid = translate_arrow(line, from, to)
        dc.draw_line(bar_from, bar_to)
        dc.draw_line(bar_mid, to.to_point)
        to = bar_mid
      end
      to
    end

  end

end
