# Wx::SF::ProngArrow - prong arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/open_arrow'

module Wx::SF

  # Class extends the Wx::OpenArrow class and encapsulates
  # arrow shape consisting of single two lines bisecting before the end of the
  # parent line shape.
  class ProngArrow < OpenArrow

    class << self
      def arrow(ratio)
        x = ratio*11; y = ratio*5
        [Wx::RealPoint.new(x,0), Wx::RealPoint.new(0, y), Wx::RealPoint.new(0,-y), Wx::RealPoint.new(0, 0)]
      end
    end

    def vertices
      @vertices ||= ProngArrow.arrow(@ratio)
    end
    private :vertices

    # Draw arrow shape at the end of a virtual line.
    # @param [Wx::RealPoint] from Start of the virtual line
    # @param [Wx::RealPoint] to End of the virtual line
    # @param [Wx::DC] dc Device context for drawing
    # @return [Wx::Point] translated connection point for arrow
    def draw(from, to, dc)
      cp, wing1, wing2, tip = translate_arrow(vertices, from, to)
      dc.with_pen(pen) do |dc|
        dc.draw_line(cp, wing1)
        dc.draw_line(cp, wing2)
        dc.draw_line(cp, tip)
      end
      cp
    end

  end

end
