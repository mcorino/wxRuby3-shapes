# Wx::SF::DiamondArrow - diamond arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/solid_arrow'

module Wx::SF

  # Class extends the Wx::SolidArrow class and encapsulates
  # solid diamond arrow shapes.
  class DiamondArrow < SolidArrow

    class << self

      def arrow(ratio)
        x = ratio*10; y = ratio*4
        [Wx::RealPoint.new(0,0), Wx::RealPoint.new(x, y), Wx::RealPoint.new(2*x,0), Wx::RealPoint.new(x,-y), Wx::RealPoint.new(2*x,0)]
      end

    end

    def vertices
      @vertices ||= DiamondArrow.arrow(@ratio)
    end
    protected :vertices

  end

end
