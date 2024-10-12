# Wx::SF::ProngArrow - prong arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/open_arrow'

module Wx::SF

  # Class extends the Wx::LineArrow class and encapsulates
  # arrow shape consisting of single two lines bisecting before the end of the
  # parent line shape.
  class ProngArrow < OpenArrow

    class << self
      def arrow(ratio)
        x = ratio*10; y = ratio*4
        [Wx::RealPoint.new(x,0), Wx::RealPoint.new(0, y), Wx::RealPoint.new(0,-y)]
      end
    end

    def vertices
      @vertices ||= ProngArrow.arrow(@ratio)
    end
    private :vertices

  end

end
