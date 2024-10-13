# Wx::SF::CrossBarArrow - crossbar arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/line_arrow'

module Wx::SF

  # Class extends the Wx::LineArrow class and encapsulates
  # arrow shape consisting of single crossbar before the end of the
  # parent line shape.
  class CrossBarArrow < LineArrow

    class << self
      def arrow(ratio)
        x = ratio*6; y = ratio*5
        [[Wx::RealPoint.new(x,y), Wx::RealPoint.new(x, -y)]]
      end
    end

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super(parent)
      scale
    end

    def lines
      @lines ||= CrossBarArrow.arrow(@ratio)
    end
    private :lines

    def scale
      @lines = nil
      @ratio = 1 + (pen_width / 2) * 0.5
    end
    protected :scale

    # Draw arrow shape at the end of a virtual line.
    # @param [Wx::RealPoint] from Start of the virtual line
    # @param [Wx::RealPoint] to End of the virtual line
    # @param [Wx::DC] dc Device context for drawing
    # @return [Wx::Point] translated connection point for arrow
    def draw(from, to, dc)
      dc.with_pen(pen) do |dc|
        lines.each do |line|
          line = translate_arrow(line, from, to)
          dc.draw_line(line[0], line[1])
        end
      end
      to.to_point
    end

  end

end
