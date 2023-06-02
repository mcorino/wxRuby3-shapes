# Wx::SF::RectShape - rectangle shape class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  class RectShape < Shape

    # default values
    module DEFAULT
      # Default value of RectShape @rect_size data member.
      SIZE = Wx::RealPoint.new(100, 50)
      # Default value of RectShape @fill data member.
      FILL = Wx::Brush.new(Wx::WHITE) if Wx::App.is_main_loop_running
      Wx.add_delayed_constant(self, :FILL) { Wx::Brush.new(Wx::WHITE) }
      # Default value of RectShape @border data member.
      BORDER = Wx::Pen.new(Wx::BLACK) if Wx::App.is_main_loop_running
      Wx.add_delayed_constant(self, :BORDER) { Wx::Pen.new(Wx::BLACK) }
    end

    property :rect_size, :fill, :border

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, diagram)
    #   User constructor.
    #   @param [Wx::RealPoint] pos Initial position
    #   @param [Wx::Size] size Initial size
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)
      size = nil
      if args.empty?
        super
      else
        pos, size, diagram = args
        super(pos, diagram)
      end
      @size = size ? size : DEFAULT::SIZE.dup
      @fill = DEFAULT::FILL
      @border = DEFAULT::BORDER
      @prev_size = @prev_position = Wx::RealPoint
    end

    # Set rectangle's fill style.
    # @param [Wx::Brush] brush Reference to a brush object
    def set_fill(brush)
      @fill = brush
    end
    alias :fill= :set_fill

    # Get current fill style.
    # @return [Wx::Brush] Current brush
    def get_fill
      @fill
    end
    alias :fill :get_fill

    # Set rectangle's border style.
    # @param [Wx::Pen] pen Reference to a pen object
    def set_border(pen)
      @border = pen
    end
    alias :border= :set_border

    # Get current border style.
    # @return [Wx::Pen] Current pen
    def get_border
      @border
    end
    alias :border :get_border

    # Set the rectangle size.
    # @overload set_rect_size(x, y)
    #   @param [Float] x Horizontal size
    #   @param [Float] y Vertical size
    # @overload set_rect_size(size)
    #   @param [Wx::RealPoint] size New size
    def set_rect_size(arg1, arg2 = nil)
      @size = arg2 ? Wx::RealPoint.new(arg1.to_f, arg2.to_f) : arg1
    end
    alias :rect_size= :set_rect_size

    # Get the rectangle size.
    # @return [Wx::RealPoint] Current size
    def get_rect_size
      @size
    end
    alias :rect_size :get_rect_size

    # Get shape's bounding box. The function can be overridden if necessary.
    # @return [Wx::Rect] Bounding rectangle
    def get_bounding_box
      apos = get_absolute_position
      Wx::Rect.new([apos.x.to_i, apos.y.to_i], [@size.x.to_i, @size.y.to_i])
    end

    # Get intersection point of the shape border and a line leading from
    # 'start' point to 'end' point. The function can be overridden if necessary.
    # @param [Wx::RealPoint] start Starting point of the virtual intersection line
    # @param [Wx::RealPoint] end_pt Ending point of the virtual intersection line
    # @return [Wx::RealPoint] Intersection point
    def get_border_point(start, end_pt)
      # HINT: override it for custom actions ...
  
      # the function calculates intersection of line leading from the shape center to
      # given point with the shape's bounding box
      bb_rct = get_bounding_box

      intersection = Shape.lines_intersection(bb_rct.top_left.to_real,
                                              Wx::RealPoint.new(bb_rct.top_right.x + 1, bb_rct.top_right.y),
                                              start, end_pt)
      intersection ||= Shape.lines_intersection(Wx::RealPoint.new(bb_rct.top_right.x + 1, bb_rct.top_right.y),
                                                Wx::RealPoint.new(bb_rct.top_right.x + 1, bb_rct.top_right.y + 1),
                                                start, end_pt)
      intersection ||= Shape.lines_intersection(Wx::RealPoint.new(bb_rct.top_right.x + 1, bb_rct.top_right.y + 1),
                                                Wx::RealPoint.new(bb_rct.top_left.x, bb_rct.top_left.y + 1),
                                                start, end_pt)
      intersection ||= Shape.lines_intersection(Wx::RealPoint.new(bb_rct.top_left.x, bb_rct.top_left.y + 1),
                                                bb_rct.top_left.to_real,
                                                start, end_pt)

      intersection || get_center
    end
  
    # Function called by the framework responsible for creation of shape handles
    # at the creation time. The function can be overridden if necessary.
    def create_handles
      # HINT: overload it for custom actions...
    
      add_handle(Shape::Handle::TYPE::LEFTTOP)
      add_handle(Shape::Handle::TYPE::TOP)
      add_handle(Shape::Handle::TYPE::RIGHTTOP)
      add_handle(Shape::Handle::TYPE::RIGHT)
      add_handle(Shape::Handle::TYPE::RIGHTBOTTOM)
      add_handle(Shape::Handle::TYPE::BOTTOM)
      add_handle(Shape::Handle::TYPE::LEFTBOTTOM)
      add_handle(Shape::Handle::TYPE::LEFT)
      add_handle(Shape::Handle::TYPE::LEFTTOP)
    end

    # Event handler called during dragging of the shape handle.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework (by the shape canvas).
    # @param [Shape::Handle] handle Reference to dragged handle
    def on_handle(handle)
      # HINT: overload it for custom actions...
    
      case handle.type
      when Shape::Handle::TYPE::LEFT
        on_left_handle(handle)

      when Shape::Handle::TYPE::LEFTTOP
        on_left_handle(handle)
        on_top_handle(handle)

      when Shape::Handle::TYPE::LEFTBOTTOM
        on_left_handle(handle)
        on_bottom_handle(handle)

      when Shape::Handle::TYPE::RIGHT
        on_right_handle(handle)

      when Shape::Handle::TYPE::RIGHTTOP
        on_right_handle(handle)
        on_top_handle(handle)

      when Shape::Handle::TYPE::RIGHTBOTTOM
        on_right_handle(handle)
        on_bottom_handle(handle)

      when Shape::Handle::TYPE::TOP
        on_top_handle(handle)

      when Shape::Handle::TYPE::BOTTOM
        on_bottom_handle(handle)
      end
      
      super
    end

    # Event handler called when the user started to drag the shape handle.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework (by the shape canvas).
    # @param [Shape::Handle] handle Reference to dragged handle
    def on_begin_handle(handle)
      @prev_position = @relative_position
      @prev_size = @size

      super
    end
  
    # Resize the shape to bound all child shapes. The function can be overridden if necessary.
    def fit_to_children
      # HINT: overload it for custom actions...
  
      # get bounding box of the shape and children set be inside it
      ch_bb = get_bounding_box
      shp_bb = ch_bb.dup
    
      @child_shapes.each do |child|
        if child.has_style?(STYLE::ALWAYS_INSIDE)
          child.get_complete_bounding_box(ch_bb, BBMODE::SELF | BBMODE::CHILDREN)
        end
      end

      unless ch_bb.empty?
        unless shp_bb.contains?(ch_bb)
          dx = ch_bb.left - shp_bb.left
          dy = ch_bb.top - shp_bb.top
    
          # resize parent shape
          shp_bb.union!(ch_bb)
          move_to(shp_bb.get_position.x, shp_bb.get_position.y)
          @size = Wx::RealPoint.new(shp_bb.get_size.x.to_f, shp_bb.get_size.y.to_f)
          if has_style?(STYLE::EMIT_EVENTS)
            evt = ShapeEvent.new(EVT_SF_SHAPE_SIZE_CHANGED, id)
            evt.set_shape(self)
            get_parent_canvas.get_event_handler.process_event(evt)
          end
    
          # move its "1st level" children if necessary
          if dx < 0 || dy < 0
            @child_shapes.each do |child|
              child.move_by(dx.to_i.abs, 0) if dx < 0
              child.move_by(0, dy.to_i.abs) if dy < 0
            end
          end
        end
      end
    end

    # Scale the shape size by in both directions. The function can be overridden if necessary
    # (new implementation should call default one ore scale shape's children manualy if neccesary).
    # @param [Float] x Horizontal scale factor
    # @param [Float] y Vertical scale factor
    # @param [Boolean] children true if the shape's children should be scaled as well, otherwise the shape will be updated after scaling via update() function.
    def scale(x, y, children = WITHCHILDREN)
      # HINT: overload it for custom actions...
      if x > 0 && y > 0
        set_rect_size(@size.x * x, @size.y * y)
    
        # call default function implementation (needed for scaling of shape's children)
        super
      end
    end
    
    protected
    
    # Draw the shape in the normal way. The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)
      # HINT: overload it for custom actions...

      dc.with_pen(@border) do
        dc.with_brush(@fill) do
          dc.draw_rectangle(get_absolute_position.to_point, @size.to_size)
        end
      end
    end

    # Draw the shape in the hover mode (the mouse cursor is above the shape).
    # The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)
      # HINT: overload it for custom actions...

      dc.with_pen(Wx::Pen.new(@hover_color, 1)) do
        dc.with_brush(@fill) do
          dc.draw_rectangle(get_absolute_position.to_point, @size.to_size)
        end
      end
    end

    # Draw the shape in the highlighted mode (another shape is dragged over this
    # shape and this shape will accept the dragged one if it will be dropped on it).
    # The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_highlighted(dc)
      # HINT: overload it for custom actions...

      dc.with_pen(Wx::Pen.new(@hover_color, 2)) do
        dc.with_brush(@fill) do
          dc.draw_rectangle(get_absolute_position.to_point, @size.to_size)
        end
      end
    end

    # Draw shadow under the shape. The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shadow will be drawn to
    def draw_shadow(dc)
      # HINT: overload it for custom actions...

      if @fill.style != Wx::BrushStyle::BRUSHSTYLE_TRANSPARENT
        dc.with_pen(Wx::TRANSPARENT_PEN) do
          dc.with_brush(get_parent_canvas.get_shadow_fill) do
            dc.draw_rectangle((get_absolute_position + get_parent_canvas.get_shadow_offset).to_point, @size.to_size)
          end
        end
      end
    end

    # Event handler called during dragging of the right shape handle.
    # The function can be overridden if necessary.
    # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_right_handle(handle)
      # HINT: overload it for custom actions...

      @size.x += handle.get_delta.x
    end

    # Event handler called during dragging of the left shape handle.
    # The function can be overridden if necessary.
    # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_left_handle(handle)
      # HINT: overload it for custom actions...
  
      dx = handle.get_delta.x.to_f
    
      # update position of children
      unless has_style?(STYLE::LOCK_CHILDREN)
        @child_shapes.each do |child|
          child.move_by(-dx, 0) if child.get_h_align == HALIGN::NONE
        end
      end
      # update position and size of the shape
      @size.x -= dx
      @relative_position.x += dx
    end

    # Event handler called during dragging of the top shape handle.
    # The function can be overridden if necessary.
    # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_top_handle(handle)
      # HINT: overload it for custom actions...
  
      dy = handle.get_delta.y.to_f
    
      # update position of children
      unless has_style?(STYLE::LOCK_CHILDREN)
        @child_shapes.each do |child|
          child.move_by(0, -dy) if child.get_v_align == VALIGN::NONE
        end
      end
      # update position and size of the shape
      @size.y -= dy
      @relative_position.y += dy
    end

    # Event handler called during dragging of the bottom shape handle.
    # The function can be overridden if necessary.
    # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_bottom_handle(handle)
      # HINT: overload it for custom actions...

      @size.y += handle.get_delta.y
    end
  end

end
