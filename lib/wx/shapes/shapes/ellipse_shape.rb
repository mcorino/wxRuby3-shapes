# Wx::SF::EllipseShape - ellipse shape class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  # Class encapsulating the ellipse shape. It extends the basic rectangular shape.
  class EllipseShape < RectShape

    # Constructor.
    # @param [Wx::RealPoint,Wx::Point] pos Initial position
    # @param [Wx::RealPoint,Wx::Size,Wx::Point] size Initial size
    # @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(pos = Shape::DEFAULT::POSITION, size = RectShape::DEFAULT::SIZE, diagram: nil)
      super
    end

    # Test whether the given point is inside the shape. The function
    # can be overridden if necessary.
    # @param [Wx::Point] pos Examined point
    # @return [Boolean] true if the point is inside the shape area, otherwise false
    def contains?(pos)
      a = get_rect_size.x/2
      b = get_rect_size.y/2
      apos = get_absolute_position
  
      m = apos.x + a
      n = apos.y + b

      pos = pos.to_point
      (((pos.x - m)*(pos.x - m))/(a*a) + ((pos.y - n)*(pos.y - n))/(b*b)) < 1
    end

    # Get intersection point of the shape border and a line leading from
    # 'start' point to 'end_pt' point. The function can be overridden if necessary.
    # @param [Wx::RealPoint] start Starting point of the virtual intersection line
    # @param [Wx::RealPoint] end_pt Ending point of the virtual intersection line
    # @return [Wx::RealPoint] Intersection point
    def get_border_point(start, end_pt)
      start = start.to_real_point; end_pt.to_real_point
      dist = start.distance_to(end_pt)
      center = get_absolute_position + [@rect_size.x/2, @rect_size.y/2]

      if dist != 0.0
        src_dx = @rect_size.x/2*(end_pt.x-start.x)/dist - (start.x-center.x)
        src_dy = @rect_size.y/2*(end_pt.y-start.y)/dist - (start.y-center.y)

        Wx::RealPoint.new(start.x + src_dx, start.y + src_dy)
      else
        center
      end
    end

    protected

    # Draw the shape in the normal way. The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)
      dc.with_pen(@border) do
        dc.with_brush(@fill) do
          dc.draw_ellipse(get_absolute_position.to_point, @rect_size.to_size)
        end
      end
    end

    # Draw the shape in the hover mode (the mouse cursor is above the shape).
    # The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)
      dc.with_pen(Wx::Pen.new(@hover_color, 1)) do
        dc.with_brush(@fill) do
          dc.draw_ellipse(get_absolute_position.to_point, @rect_size.to_size)
        end
      end
    end

    # Draw the shape in the highlighted mode (another shape is dragged over this
    # shape and this shape will accept the dragged one if it will be dropped on it).
    # The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_highlighted(dc)
      dc.with_pen(Wx::Pen.new(@hover_color, 2)) do
        dc.with_brush(@fill) do
          dc.draw_ellipse(get_absolute_position.to_point, @rect_size.to_size)
        end
      end
    end

    # Draw shadow under the shape. The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shadow will be drawn to
    def draw_shadow(dc)
      if @fill.style != Wx::BrushStyle::BRUSHSTYLE_TRANSPARENT
        dc.with_pen(Wx::TRANSPARENT_PEN) do
          dc.with_brush(get_parent_canvas.get_shadow_fill) do
            dc.draw_ellipse((get_absolute_position + get_parent_canvas.get_shadow_offset).to_point,
                            @rect_size.to_size)
          end
        end
      end
    end

  end

end
