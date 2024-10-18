# Wx - extensions
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx

  class RealPoint

    # Returns distance from this point to given point.
    # @param [Wx::RealPoint,Wx::Point,Array(Integer,Integer),Array(Float,Float)] pt2
    # @return [Float] distance to given point
    def distance_to(pt2)
      to_x, to_y = pt2
      to_x = to_x.to_f
      to_y = to_y.to_f
      Math.sqrt((to_x - self.x)*(to_x - self.x) + (to_y - self.y)*(to_y - self.y))
    end
    alias :distance :distance_to

    # Returns this point as a Wx::Size
    # @return [Wx::Size]
    def to_size
      Wx::Size.new(self.x.to_i, self.y.to_i)
    end

  end

  class Size

    # Returns this size as a Wx::RealPoint.
    # @return [Wx::RealPoint]
    def to_real_point
      Wx::RealPoint.new(self.width.to_f, self.height.to_f)
    end
    alias :to_real :to_real_point

  end

end
