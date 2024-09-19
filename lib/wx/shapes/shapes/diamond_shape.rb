# Wx::SF::DiamondShape - Diamond shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/polygon_shape'

module Wx::SF

  class DiamondShape < PolygonShape

    module DEFAULT
      DIAMOND = [Wx::RealPoint.new(0,25), Wx::RealPoint.new(50,0), Wx::RealPoint.new(100, 25), Wx::RealPoint.new(50, 50)]
    end

    # do not serialize because the vertices are assigned fixed in ctor
    excludes :vertices

    # Constructor.
    # @param [Wx::RealPoint,Wx::Point] pos Initial position
    # @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(pos = Shape::DEFAULT::POSITION, diagram: nil)
      super(pos, vertices: DEFAULT::DIAMOND, diagram: diagram)
    end

    # Test whether the given point is inside the shape. The function
    # can be overridden if necessary.
    # @param [Wx::Point] pos Examined point
    # @return [Boolean] true if the point is inside the shape area, otherwise false
    def contains?(pos)
      bb_rct = get_bounding_box
      return false unless bb_rct.contains?(pos)

      center = get_center
      k = (bb_rct.height/2).to_f/(bb_rct.width/2).to_f

      if pos.x <= center.x
        # test left-top quadrant
        return true if (pos.y <= center.y) && (pos.y >= (center.y - (pos.x - bb_rct.left)*k))
        # test left-bottom quadrant
        return true if (pos.y >= center.y) && (pos.y <= (center.y + (pos.x - bb_rct.left)*k))
      else
        # test right-top quadrant
        return true if (pos.y <= center.y) && (pos.y >= (bb_rct.top + (pos.x - center.x)*k))
        # test left-bottom quadrant
        return true if (pos.y >= center.y) && (pos.y <= (bb_rct.bottom - (pos.x - center.x)*k))
      end

      false
    end

  end

end
