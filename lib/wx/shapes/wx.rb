# Wx - extensions
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx

  class Wx::RealPoint

    # Returns distance from this point to given point.
    # @param [Wx::RealPoint,Wx::Point,Array(Integer,Integer)] pt2
    # @return [Float] distance to given point
    def distance_to(pt2)
      if Array === pt2 && pt2.size == 2
        to_x, to_y = pt2
      else
        to_x = pt2.x; to_y = pt2.y
      end
      Math.sqrt((to_x - self.x)*(to_x - self.x) + (to_y - self.y)*(to_y - self.y))
    end
    alias :distance :distance_to

    # Returns this point as a Wx::Size
    # @return [Wx::Size]
    def to_size
      Wx::Size.new(self.x.to_i, self.y.to_i)
    end

  end

end
