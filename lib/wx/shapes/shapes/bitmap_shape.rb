# Wx::SF::BitmapShape - Bitmap shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'
require 'pathname'

module Wx::SF

  # Class encapsulating the bitmap shape. The shape can display and control
  # files stored in formats supported by Wx::Bitmap class loaded from a file or created
  # from XPM image.
  class BitmapShape < RectShape

    property :can_scale, :bitmap

    # Constructor.
    # @param [Wx::RealPoint,Wx::Point] pos Initial position
    # @param [String] bmp_path Bitmap path
    # @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(pos = Shape::DEFAULT::POSITION, bmp_path = nil, diagram: nil)
      super(pos, diagram: diagram)
      @bitmap = Wx::NULL_BITMAP
      @art_path = @art_section = nil
      @bitmap_path = bmp_path
      create_from_file(bmp_path) if bmp_path
      @rescale_in_progress = false
      @can_scale = true
    end

	  # Get full name of a source BMP file (if set).
	  # @return [String,nil] String containing full file name
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
    # @param [String,Symbol] file File name (absolute or relative) or base name for art file (for Wx::ArtLocator)
    # @param [Wx::BitmapType,nil] type Bitmap type (see the wxBitmap class reference)
    # @param [String] art_path base path to look up the art file for Wx::ArtLocator
    # @param [String,nil] art_section optional owner folder name for art files for Wx::ArtLocator
    # @return [Boolean] true on success, otherwise false
    # @see Wx::ArtLocator
    def create_from_file(file, type = nil, art_path: nil, art_section: nil)
      # load bitmap from the file
      @bitmap_path = file
      @bitmap_type = type
      if File.file?(@bitmap_path.to_s)
        @bitmap = Wx::Bitmap.new
        success = @bitmap.load_file(@bitmap_path, type ? type : Wx::BITMAP_TYPE_ANY)
      else
        art_path ||= File.dirname(caller_locations(1).first.absolute_path)
        art_section ||= File.basename(caller_locations(1).first.absolute_path, '.*')
        path = Wx::ArtLocator.find_art(@bitmap_path, art_path: art_path, art_section: art_section, art_type: :bitmap, bmp_type: type)
        if path
          @bitmap = Wx::Bitmap.new
          success = @bitmap.load_file(path, type ? type : Wx::BITMAP_TYPE_ANY)
          if success
            p = Pathname.new(art_path)
            if Wx::PLATFORM == 'WXMSW'
              # take possibility of different drive into account
              @art_path = if p.relative? || art_path[0] != Dir.getwd[0]
                            art_path
                          else
                            p.relative_path_from(Dir.getwd).to_s
                          end
            else
              @art_path = p.relative? ? art_path : p.relative_path_from(Dir.getwd).to_s
            end
            @art_section = art_section
          end
        else
          @bitmap = nil
          success = false
        end
      end

      @original_bitmap = @bitmap

      if success
        @rect_size.x = @bitmap.width
        @rect_size.y = @bitmap.height

        if @can_scale
          add_style(Shape::STYLE::SIZE_CHANGE)
        else
          remove_style(Shape::STYLE::SIZE_CHANGE)
        end
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

    # Event handler called by ShapeCanvas to request,report canvas changes.
    # @param [ShapeCanvas::CHANGE] change change type indicator
    # @param [Array] _args any additional arguments
    # @return [Boolean,nil]
    def _on_canvas(change, *_args)
      if change == ShapeCanvas::CHANGE::RESCALED
        self.scale(1, 1)
      end
      super
    end

    # Handle action at handle drag beginning
    def do_begin_handle
      if @can_scale
        @rescale_in_progress = true
        @prev_pos = get_absolute_position.dup
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
        size = size.to_real_point
        if ShapeCanvas.gc_enabled?
          Wx::Bitmap.rescale(@bitmap = Wx::Bitmap.new(@original_bitmap), size.to_size)
        else
          scale = get_parent_canvas.get_scale
          Wx::Bitmap.rescale(@bitmap = Wx::Bitmap.new(@original_bitmap), (size * scale).to_size)
        end
      end
    end

	  # Draw the shape in the normal way. The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)
      # HINT: overload it for custom actions...
      if @rescale_in_progress
        _draw_bitmap(dc, @prev_pos.to_point)
    
        dc.with_brush(Wx::TRANSPARENT_BRUSH) do
          dc.with_pen(Wx::Pen.new(Wx::Colour.new(100, 100, 100), 1, Wx::PenStyle::PENSTYLE_DOT)) do
            dc.draw_rectangle(get_absolute_position.to_point, @rect_size.to_size)
          end
        end
      else
        _draw_bitmap(dc, get_absolute_position.to_point)
      end
    end

	  # Draw the shape in the hover mode (the mouse cursor is above the shape). The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)
      _draw_bitmap(dc, get_absolute_position.to_point)

      dc.with_brush(Wx::TRANSPARENT_BRUSH) do
        dc.with_pen(Wx::Pen.new(@hover_color, 1)) do
          dc.draw_rectangle(get_absolute_position.to_point, @rect_size.to_size)
        end
      end
    end

	  # Draw the shape in the highlighted mode (another shape is dragged over this shape and this shape will accept the
    # dragged one if it will be dropped on it). The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_highlighted(dc)
      _draw_bitmap(dc, get_absolute_position.to_point)

      dc.with_brush(Wx::TRANSPARENT_BRUSH) do
        dc.with_pen(Wx::Pen.new(@hover_color, 2)) do
          dc.draw_rectangle(get_absolute_position.to_point, @rect_size.to_size)
        end
      end
    end

    private

    # draw the bitmap
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    # @param [Wx::Point] pos
    def _draw_bitmap(dc, pos)
      if @bitmap && @bitmap.ok?
        dc.draw_bitmap(@bitmap, pos)
      else
        dc.with_brush(Wx::TRANSPARENT_BRUSH) do
          dc.with_pen(Wx::BLACK_PEN) do
            dc.draw_rectangle(pos, @rect_size.to_size)
            dc.draw_line(pos, [pos.x+@rect_size.x.to_i-1, pos.y+@rect_size.y.to_i-1])
            dc.draw_line([pos.x, pos.y+@rect_size.y.to_i-1], [pos.x+@rect_size.x.to_i-1, pos.y])
          end
        end
      end
    end

    # Serialization only.
    def get_bitmap
      if @bitmap && @bitmap.ok?
        [@bitmap_path, @bitmap_type, @art_path, @art_section]
      else
        [nil,nil]
      end
    end

    # Deserialization only.
    def set_bitmap(bmp_data)
      file, type, art_path, art_section = bmp_data
      if file
        create_from_file(file, type, art_path: art_path, art_section: art_section)
      end
    end

  end

end
