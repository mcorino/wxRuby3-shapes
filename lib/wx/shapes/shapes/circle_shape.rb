# Wx::SF::CircleShape - circle shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/square_shape'

module Wx::SF

  # Class encapsulating the circle shape.
  class CircleShape < SquareShape

    # Default values
    module DEFAULT
      # Default circle radius
      RADIUS = 25.0
    end

    # Constructor.
    # @param [Wx::RealPoint] pos Initial position
    # @param [Float] radius Initial circle radius
    # @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(pos = Shape::DEFAULT::POSITION, radius = DEFAULT::RADIUS, diagram: nil)
      super(pos, radius*2, diagram: diagram)
    end

    def get_radius
      @rect_size.x/2
    end
    alias :radius :get_radius

    def set_radius(rad)
      set_rect_size(rad*2, rad*2)
    end
    alias :radius= :set_radius

	  # Test whether the given point is inside the shape. The function
    # can be overridden if necessary.
    # @param [Wx::Point] pos Examined point
    # @return [Boolean] true if the point is inside the shape area, otherwise false
    def contains?(pos)
      get_center.distance_to(pos) <= radius
    end

    # Get intersection point of the shape border and a line leading from
    # 'start' point to 'end' point. The function can be overridden if necessary.
    # @param [Wx::RealPoint] start Starting point of the virtual intersection line
    # @param [Wx::RealPoint] end_pt Ending point of the virtual intersection line
    # @return [Wx::RealPoint] Intersection point
    def get_border_point(start, end_pt)
      start = start.to_real_point; end_pt.to_real_point
      dist = start.distance_to(end_pt)
      center = get_center
    
      if dist != 0.0
        rad = radius
        src_dx = rad*(end_pt.x-start.x)/dist - (start.x-center.x)
        src_dy = rad*(end_pt.y-start.y)/dist - (start.y-center.y)
    
        Wx::RealPoint.new(start.x + src_dx, start.y + src_dy)
      else
        center
      end
    end

    protected

    # Draw the shape in the normal way. The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)
      # HINT: overload it for custom actions...
      pos = get_absolute_position

      dc.with_pen(@border) do
        dc.with_brush(@fill) do
          dc.draw_circle((pos.x + @rect_size.x/2).to_i,
                         (pos.y + @rect_size.y/2).to_i,
                         (@rect_size.x/2).to_i)
        end
      end
    end

    # Draw the shape in the hover mode (the mouse cursor is above the shape).
    # The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)
      # HINT: overload it for custom actions...
      pos = get_absolute_position

      dc.with_pen(Wx::Pen.new(@hover_color, 1)) do
        dc.with_brush(@fill) do
          dc.draw_circle((pos.x + @rect_size.x/2).to_i,
                         (pos.y + @rect_size.y/2).to_i,
                         (@rect_size.x/2).to_i)
        end
      end
    end

    # Draw the shape in the highlighted mode (another shape is dragged over this
    # shape and this shape will accept the dragged one if it will be dropped on it).
    # The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_highlighted(dc)
      # HINT: overload it for custom actions...
      pos = get_absolute_position

      dc.with_pen(Wx::Pen.new(@hover_color, 2)) do
        dc.with_brush(@fill) do
          dc.draw_circle((pos.x + @rect_size.x/2).to_i,
                         (pos.y + @rect_size.y/2).to_i,
                         (@rect_size.x/2).to_i)
        end
      end
    end

    # Draw shadow under the shape. The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shadow will be drawn to
    def draw_shadow(dc)
      # HINT: overload it for custom actions...
      pos = get_absolute_position

      if @fill.style != Wx::BrushStyle::BRUSHSTYLE_TRANSPARENT
        dc.with_pen(Wx::TRANSPARENT_PEN) do
          dc.with_brush(get_parent_canvas.get_shadow_fill) do
            dc.draw_circle((pos.x + @rect_size.x/2 + get_parent_canvas.get_shadow_offset.x).to_i,
                           (pos.y + @rect_size.y/2 + get_parent_canvas.get_shadow_offset.y).to_i,
                           (@rect_size.x/2).to_i)
          end
        end
      end
    end

  end

end
