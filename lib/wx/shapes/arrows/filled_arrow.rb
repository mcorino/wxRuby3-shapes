# Wx::SF::FilledArrow - closed line drawn arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/line_arrow'

module Wx::SF

  # Class extends the Wx::LineArrow class and encapsulates
  # enclosed and filled arrow shapes.
  class FilledArrow < LineArrow

    module DEFAULT
      class << self
        def fill; @fill ||= Wx::WHITE_BRUSH.dup; end
      end
    end

    property fill: :serialize_arrow_fill

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super
      @fill = DEFAULT.fill
    end

    # Get arrow fill brush
    # @return [Wx::Brush]
    def get_fill
      @fill || (@diagram&.shape_canvas ? @diagram.shape_canvas.arrow_fill : DEFAULT.fill)
    end
    alias :fill :get_fill

    # Set arrow fill brush
    # @overload set_fill(brush)
    #   @param [Wx::Brush] brush
    # @overload set_fill(color, style=Wx::BrushStyle::BRUSHSTYLE_SOLID)
    #   @param [Wx::Colour,Symbol,String] color brush color
    #   @param [Wx::BrushStyle] style
    # @overload set_fill(stipple_bitmap)
    #   @param [Wx::Bitmap] stipple_bitmap
    def set_fill(brush)
      @fill = if args.size == 1 && Wx::Brush === args.first
                args.first
              else
                Wx::Brush.new(*args)
              end
    end
    alias :fill= :set_fill

    # (de-)serialize only
    def serialize_arrow_fill(*val)
      @fill = val.first unless val.empty?
      @fill
    end
    private :serialize_arrow_fill

  end

end
