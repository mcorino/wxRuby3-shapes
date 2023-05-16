# Wx - extensions
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx

  class Wx::RealPoint

    def distance_to(pt2)
      Math.sqrt((pt2.x - self.x)*(pt2.x - self.x) + (pt2.y - self.y)*(pt2.y - self.y))
    end
    alias :distance :distance_to

    def to_size
      Wx::Size.new(self.x.to_i, self.y.to_i)
    end

  end

end
