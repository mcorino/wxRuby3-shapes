# Wx::SF::TextShape - text shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'

module Wx::SF

  class TextShape < RectShape

    # default values
    module DEFAULT
      class << self
        # Default value of TextShape @font data member.
        def font; begin; @font = Wx::SWISS_FONT.dup; @font.point_size = 12; end unless @font; @font; end
        # Default value of TextShape @text_color data member.
        def text_color; @txtclr ||= Wx::BLACK.dup; end
        # Standard value of TextShape @fill data member
        def text_fill; @text_fill ||= Wx::TRANSPARENT_BRUSH.dup; end
        # Standard value of TextShape @border data member
        def text_border; @text_border ||= Wx::TRANSPARENT_PEN.dup; end
      end
      TEXT = 'Text'
    end

    property :text
    property text_colour: :serialize_text_colour,
             font: :serialize_text_font

    # Constructor.
    # @param [Wx::RealPoint,Wx::Point] pos Initial position
    # @param [String] txt Text content
    # @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(pos = Shape::DEFAULT::POSITION, txt = DEFAULT::TEXT, diagram: nil)
      super(pos, Wx::RealPoint.new, diagram: diagram)
      @font = nil
      @scaled_font = nil

      @line_height = 12

      @text_color = nil
      @text = txt

      @rect_size = Wx::RealPoint.new

      update_rect_size
    end

    # Set text font.
    # @overload set_text_font(font)
    #   @param [Wx::Font] font
    # @overload set_text_font(font_info)
    #   @param [Wx::FontInfo] font_info
    # @overload set_text_font(pointSize, family, style, weight, underline=false, faceName=(''), encoding=Wx::FontEncoding::FONTENCODING_DEFAULT)
    #   @param pointSize [Integer]  Size in points. See {Wx::Font#initialize}.
    #   @param family [Wx::FontFamily]  The font family. See {Wx::Font#initialize}.
    #   @param style [Wx::FontStyle]  One of {Wx::FontStyle::FONTSTYLE_NORMAL}, {Wx::FontStyle::FONTSTYLE_SLANT} and {Wx::FontStyle::FONTSTYLE_ITALIC}. See {Wx::Font#initialize}.
    #   @param weight [Wx::FontWeight]  Font weight. One of the {Wx::FontWeight} enumeration values. See {Wx::Font#initialize}.
    #   @param underline [Boolean]  The value can be true or false. See {Wx::Font#initialize}.
    #   @param faceName [String]  An optional string specifying the face name to be used. See {Wx::Font#initialize}.
    #   @param encoding [Wx::FontEncoding]  An encoding which may be one of the enumeration values of {Wx::FontEncoding}. See {Wx::Font#initialize}.
    def set_font(*args)
      @font = if args.size == 1 && Wx::Font === args.first
                args.first
              else
                Wx::Font.new(*args)
              end
      update_rect_size
    end
    alias :font= :set_font

    # Get text font.
    # @return [Wx::Font] Font
    def get_font
      @font || (@diagram&.shape_canvas ? @diagram.shape_canvas.text_font : DEFAULT.font)
    end
    alias :font :get_font

    # Set text.
    # @param [String] txt Text content
    def set_text(txt)
      @text = txt
      update_rect_size
    end
    alias :text= :set_text

    # Get text.
    # @return [String] Current text content
    def get_text
      @text
    end
    alias :text :get_text

    # Get current fill style.
    # @return [Wx::Brush] Current brush
    def get_fill
      @fill || (@diagram&.shape_canvas ? @diagram.shape_canvas.text_fill : DEFAULT.fill)
    end
    alias :fill :get_fill

    # Get current border style.
    # @return [Wx::Pen] Current pen
    def get_border
      @border || (@diagram&.shape_canvas ? @diagram.shape_canvas.text_border : DEFAULT.border)
    end
    alias :border :get_border

    # Set text color.
    # @param [Wx::Colour,String,Symbol] col Text color
    def set_text_colour(col)
      @text_color = Wx::Colour === col ? col : Wx::Colour.new(col)
    end
    alias :text_colour= :set_text_colour

    # Get text color.
    # @return [Wx::Colour] Current text color
    def get_text_colour
      @text_color || (@diagram&.shape_canvas ? @diagram.shape_canvas.text_colour : DEFAULT.text_color)
    end
    alias :text_colour :get_text_colour
    
    # Update shape (align all child shapes and resize it to fit them)
    def update(recurse = true)
      update_rect_size
      super
    end

    # Returns size of current text using current font.
    # @return [Wx::Size]
    def get_text_extent
      w = -1
      h = -1
      if get_parent_canvas
        cur_font = @scaled_font || font
        if ShapeCanvas.gc_enabled?
          Wx::GraphicsContext.draw_on(get_parent_canvas) do |gc|
            # calculate text extent
            hd = -1
            e = 0

            gc.set_font(cur_font, Wx::BLACK)

            # we must use split string to inspect all lines of possible multiline text
            h = 0
            @text.split("\n").each do |line|
              wd, hd, d, e = gc.get_text_extent(line)
              h += (hd + e).to_i
              w = (wd + d).to_i if (wd + d) > w
            end
            @line_height = (hd + e).to_i

            gc.set_font(Wx::NULL_FONT, Wx::BLACK)
          end
        else
          get_parent_canvas.paint do |dc|
            dc.set_font(cur_font)
            w, h, @line_height = dc.get_multi_line_text_extent(@text)
            dc.set_font(Wx::NULL_FONT)
          end
        end
      else
        w = @rect_size.x.to_i
        h = @rect_size.y.to_i
        @line_height = (@rect_size.y/@text.split("\n").size).to_i
      end

      Wx::Size.new(w, h)
    end

    # Updates rectangle size for this shape.
    def update_rect_size
      tsize = get_text_extent

      if tsize.is_fully_specified
        tsize.width = 1 if tsize.width <= 0
        tsize.height = 1 if tsize.height <= 0

        @rect_size.x = tsize.width.to_f
        @rect_size.y = tsize.height.to_f
      end
    end

    protected

    # Scale the rectangle size for this shape.
    # @param [Float] x Horizontal scale factor
    # @param [Float] y Vertical scale factor
    def scale_rectangle(x, y)
      if x == 1.0
        s = y
      elsif y == 1.0
        s = x
      elsif x >= y
        s = x
      else
        s = y
      end

      cur_font = @scaled_font || font

      size = cur_font.get_point_size * s
      size = 5 if size < 5

      if size == font.point_size
        @scaled_font = nil
      else
        @scaled_font ||= font.dup
        @scaled_font.set_point_size(size.to_i) unless size == @scaled_font.get_point_size
      end
      update_rect_size
    end

    # Handle's shape specific actions on handling handle events.
    # The function can be overridden if necessary.
    # @param [Shape::Handle] handle Reference to dragged handle
    # @see #on_handle
    def do_on_handle(handle)
      # HINT: overload it for custom actions...
      prev_size = get_rect_size

      # perform standard operations
      case handle.get_type
      when Shape::Handle::TYPE::LEFT
        on_left_handle(handle)
      when Shape::Handle::TYPE::RIGHT
        on_right_handle(handle)
      when Shape::Handle::TYPE::TOP
        on_top_handle(handle)
      when Shape::Handle::TYPE::BOTTOM
        on_bottom_handle(handle)
      end

      new_size = @rect_size

      sx = new_size.x / prev_size.x
      sy = new_size.y / prev_size.y
      scale(sx, sy)

      case handle.get_type
      when Shape::Handle::TYPE::LEFT
        dx = @rect_size.x - prev_size.x
        move_by(-dx, 0)
        @child_shapes.each { |shape| shape.move_by(-dx, 0) }

      when Shape::Handle::TYPE::TOP
        dy = @rect_size.y - prev_size.y
        move_by(0, -dy)
        @child_shapes.each { |shape| shape.move_by(0, -dy) }
      end
    end

	  # Draw the shape in the normal way. The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)
      super
      draw_text_content(dc)
    end

	  # Draw the shape in the hover mode (the mouse cursor is above the shape).
    # The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)
      super
      draw_text_content(dc)
    end

	  # Draw the shape in the highlighted mode (another shape is dragged over this
    # shape and this shape will accept the dragged one if it will be dropped on it).
    # The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_highlighted(dc)
      super
      draw_text_content(dc)
    end

	  # Draw shadow under the shape. The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shadow will be drawn to
    def draw_shadow(dc)
      # HINT: overload it for custom actions...

      curr_color = @text_color
      @text_color = get_parent_canvas.get_shadow_fill.get_colour
      offset = get_parent_canvas.get_shadow_offset

      move_by(offset)
      draw_text_content(dc)
      move_by(-offset.x, -offset.y)

      @text_color = curr_color
    end

    # Event handler called during dragging of the left shape handle.
    # The function can be overridden if necessary.
	  # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_left_handle(handle)
      # HINT: overload it for custom actions...

      @rect_size.x -= (handle.get_position.x - get_absolute_position.x)
    end

    # Event handler called during dragging of the top shape handle.
    # The function can be overridden if necessary.
	  # @param [Shape::Handle]handle Reference to dragged shape handle
    def on_top_handle(handle)
      # HINT: overload it for custom actions...

      @rect_size.y -= (handle.get_position.y - get_absolute_position.y)
    end

    # Event handler called during dragging of the right shape handle.
    # The function can be overridden if necessary.
	  # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_right_handle(handle)
      # HINT: overload it for custom actions...

      @rect_size.x = (handle.get_position.x - get_absolute_position.x)
    end

    # Event handler called during dragging of the bottom shape handle.
    # The function can be overridden if necessary.
	  # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_bottom_handle(handle)
      # HINT: overload it for custom actions...

      @rect_size.y = (handle.get_position.y - get_absolute_position.y)
    end

	  # Draw text shape.
	  # @param [Wx::DC] dc Device context where the text shape will be drawn to
    def draw_text_content(dc)
      dc.with_brush(fill) do
        dc.set_background_mode(Wx::BrushStyle::BRUSHSTYLE_TRANSPARENT.to_i)
        dc.set_text_foreground(@text_color)
        dc.with_font(@scaled_font || font) do
          pos = get_absolute_position
          # draw all text lines
          @text.split("\n").each_with_index do |line, i|
            dc.draw_text(line, pos.x.to_i, pos.y.to_i + i*@line_height)
          end
        end
      end
    end

    # (de-)serialize text colour; allows for nil values
    def serialize_text_colour(*val)
      @text_color = val.first unless val.empty?
      @text_color
    end

    # (de-)serialize text colour; allows for nil values
    def serialize_text_font(*val)
      @font = val.first unless val.empty?
      @font
    end

    # Deserialize attributes and recalculate rectangle size afterwards.
    # @return [self]
    def deserialize_finalize
      update_rect_size
      self
    end

    define_deserialize_finalizer :deserialize_finalize

  end

end
