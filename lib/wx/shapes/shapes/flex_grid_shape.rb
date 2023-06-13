# Wx::SF::FlexGridShape - flexible grid shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/grid_shape'

module Wx::SF

  # Class encapsulates a rectangular shape derived from {GridShape} class which acts as a flexible grid-based
  # container able to manage other assigned child shapes (it can control their position). The managed
  # shapes are aligned into defined grid with a behaviour similar to classic Wx::FlexGridSizer class.
  class FlexGridShape < GridShape


    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, rows, cols, cell_space, diagram)
    #   User constructor.
    #   @param [Wx::RealPoint] pos Initial position
    #   @param [Wx::RealPoint] size Initial size
    #   @param [Integer] cols Number of grid rows
    #   @param [Integer] rows Number of grid columns
    #   @param [Integer] cell_space Additional space between managed shapes
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)
      super
    end

    # Do layout of assigned child shapes
    def do_children_layout
      return if @cols == 0 || @rows == 0

      # initialize size arrays
      row_sizes = ::Array.new(@rows, 0)
      col_sizes = ::Array.new(@cols, 0)

      # prepare a storage for processed shapes pointers
      grid_shapes = ::Array.new(@cells.size)

      # get maximum size of all managed (child) shapes per row and column
      @cells.each_with_index do |id, i|
        if id
          col = (i % @cols)
          row = (i / @cols)

          grid_shapes[i] = shape = @child_shapes[id]
          curr_rect = shape.get_bounding_box

          # update maximum rows and columns sizes
          col_sizes[col] = curr_rect.width if (shape.get_h_align != HALIGN::EXPAND) && (curr_rect.width > col_sizes[col])
          row_sizes[row] = curr_rect.height if (shape.get_v_align != VALIGN::EXPAND) && (curr_rect.height > row_sizes[row])
        end
      end

      total_x = total_y = 0

      # put managed shapes to appropriate positions
      grid_shapes.each_with_index do |shape, i|
        if shape
          col = (i % @cols)
          row = (i / @cols)
          if col == 0
            total_x = 0
            total_y += row_sizes[row-1] if row > 0
          else
            total_x += col_sizes[col-1]
          end

          fit_shape_to_rect(shape,
                            Wx::Rect.new(total_x + (col+1)*@cell_space,
                                         total_y + (row+1)*@cell_space,
                                         col_sizes[col], row_sizes[row]))
        end
      end
    end

  end

end
