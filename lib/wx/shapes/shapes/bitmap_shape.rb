# Wx::SF::TextShape - Bitmap shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'

module Wx::SF

  # Class encapsulating the bitmap shape. The shape can display and control
  # files stored in formats supported by Wx::Bitmap class loaded from a file or created
  # from XPM image.
  class BitmapShape < RectShape

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, bmp_path, diagram)
    #   User constructor.
    #   @param [Wx::Point] pos Initial position
    #   @param [String] bmp_path Bitmap path
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)

    end

  end

end
