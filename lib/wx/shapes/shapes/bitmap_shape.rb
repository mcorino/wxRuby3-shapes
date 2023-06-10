# Wx::SF::TextShape - Bitmap shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'

module Wx::SF

  # Class encapsulating the bitmap shape. The shape can display and control
  # files stored in formats supported by Wx::Bitmap class loaded from a file or created
  # from XPM image.
  class BitmapShape < RectShape

    property :can_scale, :bitmap

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, bmp_path, diagram)
    #   User constructor.
    #   @param [Wx::Point] pos Initial position
    #   @param [String] bmp_path Bitmap path
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)
      @bitmap = Wx::NULL_BITMAP
      if args.empty?
        super
        @bitmap_path = nil
        @original_bitmap = @bitmap = nil
        @bitmap_type = nil
      else
        pos, bmp_path, diagram = args
        super(pos, RectShape::DEFAULT::SIZE.dup, diagram)
        create_from_file(bmp_path)
      end
      @rescale_in_progress = false
      @can_scale = true
    end

	  # Get full name of a source BMP file.
	  # @return [String] String containing full file name
    def get_bitmap_path
      @bitmap_path
    end

	  # Enable/disable scaling mode of the bitmap.
	  # @param [Boolean] canscale Set true if the bitmap shape could be scaled
    def enable_scale(canscale)
      @can_scale = canscale
    end
    alias :set_can_scale :enable_scale

	  # Get information about the possibility of the shape scaling.
	  # @return [Boolean] true if the shape can be scaled, otherwise false
    def can_scale?
      @can_scale
    end
    alias :get_can_scale :can_scale?

	  # Load a bitmap from the file.
    # @param [String] file File name (absolute or relative)
    # @param [Wx::BitmapType,nil] type Bitmap type (see the wxBitmap class reference)
    # @return [Boolean] true on success, otherwise false
    def create_from_file(file, type = nil)
      # load bitmap from the file
      @bitmap_path = file
      @bitmap_type = type
      if File.file?(@bitmap_path)
        @bitmap = Wx::Bitmap.new
        success = @bitmap.load_file(@bitmap_path, type ? type : Wx::BITMAP_TYPE_ANY)
      elsif (path = Wx::ArtLocator.find_art(@bitmap_path, art_type: :bitmap, bmp_type: type))
        @bitmap = Wx::Bitmap.new
        success = @bitmap.load_file(@bitmap_path, type ? type : Wx::BITMAP_TYPE_ANY)
      else
        @bitmap = nil
        success = false
      end

      @original_bitmap = @bitmap
    
      @rect_size.x = @bitmap.width
      @rect_size.y = @bitmap.height
    
      if @can_scale
        add_style(Shape::STYLE::SIZE_CHANGE)
      else
        remove_style(Shape::STYLE::SIZE_CHANGE)
      end
    
      success
    end

	  # Event handler called during dragging of the shape handle. The function can be overridden if necessary.
	  # @param [Shape::Handle] handle Reference to the dragged shape handle
    def on_handle(handle)
      if @can_scale
        super
      else
        remove_style(STYLE::SIZE_CHANGE)
      end
    end

	  # Event handler called when the user finished dragging of the shape handle. The function can be overridden if necessary.
	  # @param [Shape::Handle] handle Reference to the dragged shape handle
    def on_end_handle(handle)
      if @can_scale
        @rescale_in_progress = false
        rescale_image(@rect_size)
      end

      super
    end

    protected

    # Handle action at handle drag beginning
    def do_begin_handle
      if @can_scale
        @rescale_in_progress = true
        @prev_pos = get_absolute_position
      end
    end

    # Scale the rectangle size for this shape.
    # @param [Float] x Horizontal scale factor
    # @param [Float] y Vertical scale factor
    def scale_rectangle(x, y)
      if @can_scale
        @rect_size.x *= x
        @rect_size.y *= y

        rescale_image(@rect_size) unless @rescale_in_progress
      end
    end

	  # Rescale the bitmap shape so it will fit the given extent. The
    # shape position is not involved (the left-top bitmap corner is not moved).
	  # @param [Wx::RealPoint] size New bitmap size
    def rescale_image(size)
      if get_parent_canvas && @original_bitmap && @original_bitmap.ok?
        image = @original_bitmap.convert_to_image

        if ShapeCanvas.gc_enabled?
          image.rescale(size.x.to_i, size.y.to_i,
                        Wx::ImageResizeQuality::IMAGE_QUALITY_NORMAL)
        else
          image.rescale((size.x * get_parent_canvas.get_scale).to_i, (size.y * get_parent_canvas.get_scale).to_i,
                        Wx::ImageResizeQuality::IMAGE_QUALITY_NORMAL)
        end

        @bitmap = Wx::Bitmap.new(image)
      end
    end

	  # Draw the shape in the normal way. The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)
      # HINT: overload it for custom actions...
      if @rescale_in_progress
        _draw_bitmap(@prev_pos.to_point)
    
        dc.with_brush(Wx::TRANSPARENT_BRUSH) do
          dc.with_pen(Wx::Pen.new(Wx::Colour.new(100, 100, 100), 1, Wx::PenStyle::PENSTYLE_DOT)) do
            dc.draw_rectangle(get_absolute_position.to_point, [@rect_size.x.to_i, @rect_size.y.to_i])
          end
        end
      else
        _draw_bitmap(get_absolute_position.to_point)
      end
    end

	  # Draw the shape in the hover mode (the mouse cursor is above the shape). The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)
      _draw_bitmap(get_absolute_position.to_point)

      dc.with_brush(Wx::TRANSPARENT_BRUSH) do
        dc.with_pen(Wx::Pen.new(@hover_color, 1)) do
          dc.draw_rectangle(get_absolute_position.to_point, [@rect_size.x.to_i, @rect_size.y.to_i])
        end
      end
    end

	  # Draw the shape in the highlighted mode (another shape is dragged over this shape and this shape will accept the
    # dragged one if it will be dropped on it). The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_highlighted(dc)
      _draw_bitmap(get_absolute_position.to_point)

      dc.with_brush(Wx::TRANSPARENT_BRUSH) do
        dc.with_pen(Wx::Pen.new(@hover_color, 2)) do
          dc.draw_rectangle(get_absolute_position.to_point, [@rect_size.x.to_i, @rect_size.y.to_i])
        end
      end
    end

    private

    # draw the bitmap
    # @param [Wx::Point] pos
    def _draw_bitmap(pos)
      if @bitmap && @bitmap.ok?
        dc.draw_bitmap(@bitmap, pos)
      else
        dc.with_brush(Wx::TRANSPARENT_BRUSH) do
          dc.with_pen(Wx::BLACK_PEN) do
            dc.draw_rectangle(pos, [@rect_size.x.to_i, @rect_size.y.to_i])
            dc.draw_line(pos, [pos.x+@rect_size.x.to_i-1, pos.y+@rect_size.y.to_i-1])
            dc.draw_line([pos.x, pos.y+@rect_size.y.to_i-1], [pos.x+@rect_size.x.to_i-1, pos.y])
          end
        end
      end
    end

    # Serialization only.
    def get_bitmap
      if @bitmap && @bitmap.ok?
        [@bitmap_path, @bitmap_type]
      else
        [nil,nil]
      end
    end

    # Deserialization only.
    def set_bitmap(bmp_data)
      path, type = bmp_data
      if path
        create_from_file(path, type)
      end
    end

  end

end
