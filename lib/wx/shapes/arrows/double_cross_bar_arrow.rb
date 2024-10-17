# Wx::SF::DoubleCrossBarArrow - double crossbar arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/cross_bar_arrow'

module Wx::SF

  # Class extends the Wx::CrossBarArrow class and encapsulates
  # arrow shape consisting of double crossbar before the end of the
  # parent line shape.
  class DoubleCrossBarArrow < CrossBarArrow

    class << self
      def arrow(ratio)
        x = ratio*7; y = ratio*6
        [[Wx::RealPoint.new(2+x/2,y), Wx::RealPoint.new(2+x/2, -y)],[Wx::RealPoint.new(2+x,y), Wx::RealPoint.new(2+x, -y), Wx::RealPoint.new(2+x, 0)]]
      end
    end

    def lines
      @lines ||= DoubleCrossBarArrow.arrow(@ratio)
    end
    private :lines

  end

end
