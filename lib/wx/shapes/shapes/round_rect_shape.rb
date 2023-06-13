# Wx::SF::RoundRectShape - rounded rectangle shape class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  # Class encapsulating rounded rectangle. It extends the basic rectangular shape.
  class RoundRectShape < RectShape

    RADIUS = 20

    property :radius

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, diagram)
    #   User constructor.
    #   @param [Wx::RealPoint] pos Initial position
    #   @param [Wx::RealPoint] size Initial size
    #   @param [Float] radius Corner radius
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)
      if args.empty?
        super
        @radius = RADIUS
      else
        pos, size, @radius, diagram = args
        super(pos, size, diagram)
      end
    end

    # Access (get/set) radius.
    attr_accessor :radius

    # Test whether the given point is inside the shape. The function
    # can be overridden if necessary.
    # @param [Wx::Point] pos Examined point
    # @return [Boolean] true if the point is inside the shape area, otherwise false
    def contains?(pos)
      return super if @radius == 0.0

      pos = pos.to_point
      # get original bounding box
      shp_bb = get_bounding_box
    
      # calculate modified boxes
      hr = shp_bb.dup.deflate(0, @radius.to_i)
      vr = shp_bb.dup.deflate(@radius.to_i, 0)
    
      # test whether given position is inside body rect or rounded corners
      if hr.contains?(pos)
        return true
      elsif vr.contains?(pos)
        return true
      elsif in_circle?(pos, shp_bb.top_left + [@radius, @radius.to_i])
        return true
      elsif in_circle?(pos, shp_bb.bottom_left + [@radius.to_i, -@radius.to_i])
        return true
      elsif in_circle?(pos, shp_bb.top_right + [-@radius.to_i, @radius.to_i])
        return true
      elsif is_in_circle(pos, shp_bb.bottom_right + [-@radius.to_i, -@radius.to_i])
        return true
      end
    
      return false
    end

    protected

    # Draw the shape in the normal way. The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)
      if @radius == 0.0
        super
        return
      end
      dc.with_pen(@border) do
        dc.with_brush(@fill) do
          dc.draw_rounded_rectangle(get_absolute_position.to_point, @rect_size.to_size, @radius)
        end
      end
    end

    # Draw the shape in the hover mode (the mouse cursor is above the shape).
    # The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)
      if @radius == 0.0
        super
        return
      end
      dc.with_pen(Wx::Pen.new(@hover_color, 1)) do
        dc.with_brush(@fill) do
          dc.draw_rounded_rectangle(get_absolute_position.to_point, @rect_size.to_size, @radius)
        end
      end
    end

    # Draw the shape in the highlighted mode (another shape is dragged over this
    # shape and this shape will accept the dragged one if it will be dropped on it).
    # The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_highlighted(dc)
      if @radius == 0.0
        super
        return
      end
      dc.with_pen(Wx::Pen.new(@hover_color, 2)) do
        dc.with_brush(@fill) do
          dc.draw_rounded_rectangle(get_absolute_position.to_point, @rect_size.to_size, @radius)
        end
      end
    end

    # Draw shadow under the shape. The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shadow will be drawn to
    def draw_shadow(dc)
      if @radius == 0.0
        super
        return
      end
      if @fill.style != Wx::BrushStyle::BRUSHSTYLE_TRANSPARENT
        dc.with_pen(Wx::TRANSPARENT_PEN) do
          dc.with_brush(get_parent_canvas.get_shadow_fill) do
            dc.draw_rounded_rectangle((get_absolute_position + get_parent_canvas.get_shadow_offset).to_point,
                                      @rect_size.to_size, @radius)
          end
        end
      end
    end

    # Auxiliary function. Checks whether the point is inside a circle with given center. The circle's radius
    # is the rounded rect corner radius.
    # @param [Wx::Point] pos Examined point
    # @param [Wx::Point] center Circle center
    # @return [Boolean]
    def in_circle?(pos, center)
      center.to_real_point.distance_to(pos.to_real_point) <= @radius
    end

  end

end
