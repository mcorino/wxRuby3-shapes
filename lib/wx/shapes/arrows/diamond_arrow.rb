# Wx::SF::ArrowBase - diamond arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/solid_arrow'

module Wx::SF

  class DiamondArrow < SolidArrow

    class << self

      def diamond_arrow
        @diamond_arrow ||= [Wx::RealPoint.new(0,0), Wx::RealPoint.new(10,4), Wx::RealPoint.new(20,0), Wx::RealPoint.new(10,-4)]
      end

    end

    # Draw arrow shape at the end of a virtual line.
    # @param [Wx::RealPoint] from Start of the virtual line
    # @param [Wx::RealPoint] to End of the virtual line
    # @param [Wx::DC] dc Device context for drawing
    def draw(from, to, dc)
      rarrow = translate_arrow(DiamondArrow.diamond_arrow, from, to)
      dc.with_pen(@pen) do |dc|
        dc.with_brush(@fill) do |dc|
          dc.draw_polygon(rarrow)
        end
      end
    end

  end

end
