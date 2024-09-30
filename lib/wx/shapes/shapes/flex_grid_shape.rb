# Wx::SF::FlexGridShape - flexible grid shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/grid_shape'

module Wx::SF

  # Class encapsulates a rectangular shape derived from {GridShape} class which acts as a flexible grid-based
  # container able to manage other assigned child shapes (it can control their position). The managed
  # shapes are aligned into defined grid with a behaviour similar to classic Wx::FlexGridSizer class.
  class FlexGridShape < GridShape


    # Constructor.
    # @param [Wx::RealPoint,Wx::Point] pos Initial position
    # @param [Wx::RealPoint,Wx::Size,Wx::Point] size Initial size
    # @param [Integer] cols Number of grid columns
    # @param [Integer] max_rows Maximum number of grid rows
    # @param [Integer] cell_space Additional space between managed shapes
    # @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(pos = Shape::DEFAULT::POSITION, size = RectShape::DEFAULT::SIZE,
                   cols: DEFAULT::COLUMNS, max_rows: 0, cell_space: DEFAULT::CELLSPACE, diagram: nil)
      super
    end

    # Do layout of assigned child shapes
    def do_children_layout
      return if @cols == 0 || @rows == 0

      # get maximum size of all managed (child) shapes per row and column
      row_sizes, col_sizes = get_max_child_sizes
      total_x = total_y = 0

      # put managed shapes to appropriate positions
      @cells.each_with_index do |shape, i|
        col = (i % @cols)
        row = (i / @cols)
        if col == 0
          total_x = 0
          total_y += row_sizes[row-1] if row > 0
        else
          total_x += col_sizes[col-1]
        end

        if shape
          fit_shape_to_rect(shape,
                            Wx::Rect.new(total_x + (col+1)*@cell_space,
                                         total_y + (row+1)*@cell_space,
                                         col_sizes[col], row_sizes[row]))
        end
      end
    end

    protected

    def get_max_child_sizes
      # initialize size arrays
      row_sizes = ::Array.new(@rows, 0)
      col_sizes = ::Array.new(@cols, 0)

      # get maximum size of all managed (child) shapes per row and column
      @cells.each_with_index do |shape, i|
        if shape
          col = (i % @cols)
          row = (i / @cols)

          curr_rect = shape.get_bounding_box

          # update maximum rows and columns sizes
          col_sizes[col] = curr_rect.width if (shape.get_h_align != HALIGN::EXPAND) && (curr_rect.width > col_sizes[col])
          row_sizes[row] = curr_rect.height if (shape.get_v_align != VALIGN::EXPAND) && (curr_rect.height > row_sizes[row])
        end
      end
      [row_sizes, col_sizes]
    end

    def find_cell(child_rect)
      # get maximum size of all managed (child) shapes per row and column
      row_sizes, col_sizes = get_max_child_sizes

      total_x = total_y = 0

      # find the cell index where the new or dragged child is positioned above and in front of
      offset = get_bounding_box.top_left
      cell_count.times.find do |cell|
        col = (cell % @cols)
        row = (cell / @cols)
        if col == 0
          total_x = 0
          total_y += row_sizes[row-1] if row > 0
        else
          total_x += col_sizes[col-1]
        end
        cell_rct = Wx::Rect.new(total_x + (col+1)*@cell_space,
                                total_y + (row+1)*@cell_space,
                                col_sizes[col], row_sizes[row]).offset!(offset)
        child_rect.right <= cell_rct.right && child_rect.bottom <= cell_rct.bottom
      end
    end

  end

end
