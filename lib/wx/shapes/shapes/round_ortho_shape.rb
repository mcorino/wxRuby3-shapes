# Wx::SF::RoundOrthoLineShape - rounded orthogonal line shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/ortho_shape'

module Wx::SF

  # Rounded orthogonal line shape. The class extends OrthoLineShape class and allows
  # user to create connection line orthogonal to base axis with round corners.
  class RoundOrthoLineShape < OrthoLineShape

    MAX_RADIUS = 7

    property :max_radius

    # @overload initialize()
    #   default constructor
    # @overload initialize(src, trg, path, manager)
    #   @param [Wx::SF::Serializable::ID] src ID of the source shape
    #   @param [Wx::SF::Serializable::ID] trg ID of the target shape
    #   @param [Array<Wx::RealPoint>] path List of the line control points (can be empty)
    #   @param [Diagram] diagram containing diagram
    def initialize(*args)
      super
      @max_radius = MAX_RADIUS
    end

    # Access (set/get) maximum radius.
    attr_accessor :max_radius

    protected

    # Draw one orthogonal line segment.
    # @param [Wx::DC] dc Device context
    # @param [Wx::RealPoint] src Starting point of the ortho line segment
    # @param [Wx::RealPoint] trg Ending point of the ortho line segment
    # @param [SEGMENTCPS] cps Connection points used by the line segment
    def draw_line_segment(dc, src, trg, cps)
      if (trg.x == src.x) || (trg.y == src.y)
        dc.draw_line(src.x, src.y, trg.x, trg.y)
        return
      end

      direction = get_segment_direction(src, trg, cps)

      dx = trg.x - src.x
      dy = trg.y - src.y
      kx = dx < 0 ? -1 : 1
      ky = dy < 0 ? 1 : -1
    
      pt_center = Wx::RealPoint.new((src.x + trg.x)/2, (src.y + trg.y)/2)
      
      dc.with_brush(Wx::TRANSPARENT_BRUSH) do

        if is_two_segment(cps)
          if direction < 1.0
            r = (dy * @max_radius/100).abs < @max_radius ? (dy * @max_radius/100).abs : @max_radius

            dc.draw_line(src.x, src.y, trg.x - r * kx, src.y)
            dc.draw_line(trg.x, src.y - r * ky, trg.x, trg.y)

            if r > 0
              if (ky > 0 && kx > 0) || (ky < 0 && kx < 0)
                dc.draw_arc(trg.x - r * kx, src.y, trg.x, src.y - r * ky, trg.x - r * kx, src.y - r * ky)
              else
                dc.draw_arc(trg.x, src.y - r * ky, trg.x - r * kx, src.y, trg.x - r * kx, src.y - r * ky)
              end
            end
          else
            r = (dx * @max_radius/100).abs < @max_radius ? (dx * @max_radius/100) : @max_radius

            dc.draw_line(src.x, src.y, src.x, trg.y + r * ky)
            dc.draw_line(src.x + r * kx, trg.y, trg.x, trg.y)

            if r > 0
              if (ky > 0 && kx > 0) || (ky < 0 && kx < 0)
                dc.draw_arc(src.x + r * kx, trg.y, src.x, trg.y + r * ky, src.x + r * kx, trg.y + r * ky)
              else
                dc.draw_arc(src.x, trg.y + r * ky, src.x + r * kx, trg.y, src.x + r * kx, trg.y + r * ky)
              end
            end
          end

        else
          if direction < 1
            r = (dy * @max_radius/100).abs < @max_radius ? (dy * @max_radius/100).abs : @max_radius

            dc.draw_line(src.x, src.y, pt_center.x - r * kx, src.y)
            dc.draw_line(pt_center.x, src.y - r * ky, pt_center.x, trg.y + r * ky)
            dc.draw_line(pt_center.x + r * kx, trg.y, trg.x, trg.y)

            if r > 0
              if (ky > 0 && kx > 0) || (ky < 0 && kx < 0)
                dc.draw_arc(pt_center.x - r * kx, src.y, pt_center.x, src.y - r * ky, pt_center.x - r * kx, src.y - r * ky)
                dc.draw_arc(pt_center.x + r * kx, trg.y, pt_center.x, trg.y + r * ky, pt_center.x + r * kx, trg.y + r * ky )
              else
                dc.draw_arc(pt_center.x, src.y - r * ky, pt_center.x - r * kx, src.y, pt_center.x - r * kx, src.y - r * ky)
                dc.draw_arc(pt_center.x, trg.y + r * ky, pt_center.x + r * kx, trg.y, pt_center.x + r * kx, trg.y + r * ky)
              end
            end
          else
            r = (dx * @max_radius/100) < @max_radius ? (dx * @max_radius/100) : @max_radius

            dc.draw_line(src.x, src.y, src.x, pt_center.y + r * ky)
            dc.draw_line(src.x + r * kx, pt_center.y, trg.x - r * kx, pt_center.y)
            dc.draw_line(trg.x, pt_center.y - r * ky, trg.x, trg.y)

            if r > 0
              if (ky > 0 && kx > 0) || (ky < 0 && kx < 0)
                dc.draw_arc(src.x + r * kx, pt_center.y, src.x, pt_center.y + r * ky, src.x + r * kx, pt_center.y + r * ky)
                dc.draw_arc(trg.x - r * kx, pt_center.y, trg.x, pt_center.y - r * ky, trg.x - r * kx, pt_center.y - r * ky)
              else
                dc.draw_arc(src.x, pt_center.y + r * ky, src.x + r * kx, pt_center.y, src.x + r * kx, pt_center.y + r * ky)
                dc.draw_arc(trg.x, pt_center.y - r * ky, trg.x - r * kx, pt_center.y, trg.x - r * kx, pt_center.y - r * ky)
              end
            end
          end
        end

      end
    end

  end

end
