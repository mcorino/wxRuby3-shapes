# Wx::SF::Shape::Handle - shape handle class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  class Shape

    # Class encapsulates shape's handle. The class shouldn't be used separately; see
    # Wx::Shape class for more detailed information about functions used for managing of shape
    # handles and handling their events
    class Handle

      # Handle type
      class TYPE < Wx::Enum
        LEFTTOP = self.new(0)
        TOP = self.new(1)
        RIGHTTOP = self.new(2)
        RIGHT = self.new(3)
        RIGHTBOTTOM = self.new(4)
        BOTTOM = self.new(5)
        LEFTBOTTOM = self.new(6)
        LEFT = self.new(7)
        LINECTRL = self.new(8)
        LINESTART = self.new(9)
        LINEEND = self.new(10)
        UNDEF = self.new(11)
      end

      # Constructor
      # @param [Wx::Shape] parent Parent shape
      # @param [TYPE] type Handle type
      # @param [Integer] id Handle ID (useful only for line controls handles)
      def initialize(parent=nil, type=TYPE::UNDEF, id=-1)
        @parent_shape = parent
        @type = type
        @id = id
        @startPos = Wx::Point.new
        @prevPos = Wx::Point.new
        @currPos = Wx::Point.new

        @visible = false
        @mouse_over = false
      end

      # Get or set Handle type
      # @param [TYPE] type Handle type to set
      # @return [TYPE] Handle type
      attr_accessor :type

      # Get parent shape.
      # @return [Wx::Shape] parent shape
      attr_reader :parent_shape

      # Set or get handle's ID.
      # @param [Integer] id Handle's ID
      # @return [Integer] Handle's ID
      attr_accessor :id

      # Get current handle position.
      # @return [Wx::Point] Handle position
      def get_position
        @currPos
      end
      alias :position :get_position

      # Get current handle delta (difference between current and previous position).
      # @return [Wx::Point] Handle delta
      def get_delta
        @currPos - @prevPos
      end
      alias :delta :get_delta

      # Get current total handle delta (difference between current and starting position
      # stored at the beginning of the dragging process).
      # @return [Wx::Point] Total handle delta
      def get_total_delta
        @currPos - @startPos
      end
      alias :total_delta :get_total_delta

      # Show/hide handle
      # @param [Boolean] show true if the handle should be visible (active), otherwise false
      def show(show = true)
        @visible = !!show
      end

      # Returns true if the handle is visible, otherwise false
      def visible?
        @visible
      end

      # Refresh (repaint) the handle
      # @return [void]
      def refresh
        @parent_shape.refresh(SF::DELAYED) if @parent_shape
      end

      # Find out whether given point is inside the handle.
      # @param [Wx::Point,Array(Integer,Integer)] pos Examined point
      # @return [Boolean] true if the point is inside the handle, otherwise false
      def contains(pos)
        handle_rect.contains(pos)
      end
      alias contains? :contains

      protected

      # Draw handle.
      # @param [Wx::DC] dc Device context where the handle will be drawn
      def draw(dc)
        if @visible && @parent_shape
          if @mouse_over
            draw_hover(dc)
          else
            draw_normal(dc)
          end
        end
      end

      # Draw handle in the normal way.
      # @param [Wx::DC] dc Device context where the handle will be drawn
      def draw_normal(dc)
        dc.with_pen(Wx::PLATFORM == 'WXGTK' ? Wx::TRANSPARENT_PEN : Wx::BLACK_PEN) do |dc|
          if Wx.has_feature?(:USE_GRAPHICS_CONTEXT)
            if ShapeCanvas::gc_enabled?
              dc.brush = Wx::Brush.new(Wx::Colour.new(0, 0, 0, 128))
            else
              dc.brush = Wx::BLACK_BRUSH
              dc.logical_function = Wx::RasterOperationMode::INVERT
            end
          else
            dc.brush = Wx::BLACK_BRUSH
            dc.logical_function = Wx::RasterOperationMode::INVERT
          end

          dc.draw_rectangle(handle_rect)
          dc.logical_function = Wx::RasterOperationMode::COPY

          dc.brush = Wx::NULL_BRUSH
        end
      end

      # Draw handle in the "hover" way (the mouse pointer is above the handle area).
      # @param [Wx::DC] dc Device context where the handle will be drawn
      def draw_hover(dc)
        if @parent_shape.contains_style(Shape::STYLE::SIZE_CHANGE)
          dc.with_pen(Wx::BLACK_PEN) do
            dc.with_brush(Wx::Brush.new(@parent_shape.hover_colour)) do
              dc.draw_rectangle(handle_rect)
            end
          end
        else
          draw_normal(dc)
        end
      end

      # Set parent shape.
      # @param [Wx::Shape] parent parent shape to set
      def parent_shape=(parent)
        @parent_shape = parent
      end

      # Get handle rectangle.
      # @return [Wx::Rect] Handle rectangle
      def handle_rect
        if @parent_shape
          brct = @parent_shape.bounding_box
          case @type
          when TYPE::LEFTTOP
            hrct = Wx::Rect.new(brct.top_left, Wx::Size.new(7,7))
          when TYPE::TOP
            hrct = Wx::Rect.new(wxPoint(brct.left + brct.width/2, brct.top), Wx::Size.new(7,7))
          when TYPE::RIGHTTOP
            hrct = Wx::Rect.new(brct.top_right, Wx::Size.new(7,7))
          when TYPE::RIGHT
            hrct = Wx::Rect.new(wxPoint(brct.right, brct.top + brct.height/2), Wx::Size.new(7,7))
          when TYPE::RIGHTBOTTOM
            hrct = Wx::Rect.new(brct.bottom_right, Wx::Size.new(7,7))
          when TYPE::BOTTOM
            hrct = Wx::Rect.new(wxPoint(brct.left + brct.width/2, brct.bottom), Wx::Size.new(7,7))
          when TYPE::LEFTBOTTOM
            hrct = Wx::Rect.new(brct.bottom_left, Wx::Size.new(7,7))
          when TYPE::LEFT
            hrct = Wx::Rect.new(wxPoint(brct.left, brct.top + brct.height/2), Wx::Size.new(7,7))
          when TYPE::LINECTRL
            pt = @parent_shape.control_points.item(@id).data
            hrct = Wx::Rect.new(wxPoint(pt.x.to_i, pt.y.to_i), Wx::Size.new(7,7))
          when TYPE::LINEEND, TYPE::LINESTART
            pt = @type == TYPE::LINESTART ? @parent_shape.src_point : @parent_shape.trg_point
            hrct = Wx::Rect.new(wxPoint(pt.x.to_i, pt.y.to_i), Wx::Size.new(7,7))
          else
            hrct = Wx::Rect.new
          end

          hrct.offset([-3, -3])
          hrct
        else
          Wx::Rect.new
        end
      end

      private

      # Event handler called when the mouse pointer is moving above shape canvas.
      # @param [Wx::Point] pos Current mouse position
      def _on_mouse_move(pos)
        if @visible
          if contains?(pos)
            unless @mouse_over
              @mouse_over = true
              refresh
            end
          else
            if @mouse_over
              @mouse_over = false
              refresh
            end
          end
        end
      end

      # Event handler called when the handle is started to be dragged.
      # @param [Wx::Point] pos Current mouse position
      def _on_begin_drag(pos)
        @prevPos = @startPos = @currPos = pos
        @parent_shape.on_begin_handle(self) if @parent_shape
      end

      # Event handler called when the handle is dragged.
      # @param [Wx::Point] pos Current mouse position
      def _on_dragging(pos)
        if @visible && @parent_shape && @parent_shape.contains_style(Shape::STYLE::SIZE_CHANGE)
          if pos != @prevPos
            prevRct = @parent_shape.bounding_box

            @currPos = pos

            case @type
            when TYPE::LEFTTOP
              @parent_shape._on_handle(self) if (pos.x < prevRct.right) && (pos.y < prevRct.bottom)

            when TYPE::TOP
              @parent_shape._on_handle(self) if (pos.y < prevRct.bottom)

            when TYPE::RIGHTTOP
              @parent_shape._on_handle(self) if ((pos.x > prevRct.left) && (pos.y < prevRct.bottom))

            when TYPE::RIGHT
              @parent_shape._on_handle(self) if (pos.x > prevRct.left)

            when TYPE::RIGHTBOTTOM
              @parent_shape._on_handle(self) if ((pos.x > prevRct.left) && (pos.y > prevRct.top))

            when TYPE::BOTTOM
              @parent_shape._on_handle(self) if (pos.y > prevRct.top)

            when TYPE::LEFTBOTTOM
              @parent_shape._on_handle(self) if ((pos.x < prevRct.right) && (pos.y > prevRct.top))

            when TYPE::LEFT
              @parent_shape._on_handle(self) if (pos.x < prevRct.right)

            when TYPE::LINESTART, TYPE::LINEEND, TYPE::LINECTRL
              @parent_shape._on_handle(self)

            end
          end

          @prevPos = pos
        end
      end

      # Event handler called when the handle is released.
      # @param [Wx::Point] _pos Current mouse position
      def _on_end_drag(_pos)
        @parent_shape.on_end_handle(self) if @parent_shape
      end

    end

  end

end
