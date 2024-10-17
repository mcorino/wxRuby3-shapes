# Wx::SF::SquareArrow - square arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/solid_arrow'

module Wx::SF

  # Class extends the Wx::SolidArrow class and encapsulates
  # square arrow shapes.
  class SquareArrow < SolidArrow

    # Default square size
    SIZE = 11

    class << self

      def arrow(size)
        y = size / 2.0
        [Wx::RealPoint.new(0, y), Wx::RealPoint.new(size, y), Wx::RealPoint.new(size, -y), Wx::RealPoint.new(0 ,-y), Wx::RealPoint.new(size, 0)]
      end

    end

    # Get the circle radius
    def get_size
      (SIZE * @ratio).to_i
    end
    alias :size :get_size

    def vertices
      @vertices ||= SquareArrow.arrow(get_size)
    end
    protected :vertices

  end

end
