# Wx::SF::GridShape - grid shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'
require 'wx/shapes/shapes/manager_shape'

module Wx::SF
  
  # Class encapsulates a rectangular shape derived from Wx::SF::RectShape class which acts as a grid-based
  # container able to manage other assigned child shapes (it can control their position). The managed
  # shapes are aligned into defined grid with a behaviour similar to classic Wx::GridSizer class.
  class GridShape < RectShape

    include ManagerShape

    # default values
    module DEFAULT
      # Default value of GridShape @cols data member.
      COLUMNS  = 3
      # Default value of GridShape @cell_space data member.
      CELLSPACE  = 5
    end

    property :cols, :max_rows, :cell_space, :cells

    # Constructor.
    # @param [Wx::RealPoint,Wx::Point] pos Initial position
    # @param [Wx::RealPoint,Wx::Size,Wx::Point] size Initial size
    # @param [Integer] cols Number of grid columns
    # @param [Integer] max_rows Maximum number of grid rows
    # @param [Integer] cell_space Additional space between managed shapes
    # @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(pos = Shape::DEFAULT::POSITION, size = RectShape::DEFAULT::SIZE,
                   cols: DEFAULT::COLUMNS, max_rows: 0, cell_space: DEFAULT::CELLSPACE, diagram: nil)
      super(pos, size, diagram: diagram)
      @cols = [1, cols.to_i].max   # at least one column
      @max_rows = [0, max_rows.to_i].max              # no or >=1 max rows
      @cell_space = [0, cell_space.to_i].max
      @rows = 1
      @cells = []
      remove_style(Shape::STYLE::SIZE_CHANGE)
    end

    attr_reader :max_rows

    # Sets the maximum number of rows for the grid (by default there this value is 0 == no maximum).
    # In case the number of already managed cells exceeds the new maximum no change is made.
    # @return [Integer] the active maximum
    def set_max_rows(num)
      # only change as long as this does not invalidate already managed cells
      @max_rows = num unless (num * @cols) < @cells.size
      @max_rows
    end
    alias :max_rows= :set_max_rows

    # Set grid dimensions.
    # @param [Integer] rows Number of rows
    # @param [Integer] cols Number of columns
    def set_dimensions(rows, cols)
      return if (new_size = rows * cols) == 0

      @rows = rows
      @cols = cols

      @cells.slice!(0, new_size) if new_size < @cells.size
    end

    # Get grid dimensions.
    # @return [Array(Integer,Integer)] row and col numbers
    def get_dimensions
      [@rows, @cols]
    end

    # Get number of available grid cells
    # @return [Integer]
    def get_cell_count
      @rows * @cols
    end
    alias :cell_count :get_cell_count

    # Set space between grid cells (managed shapes).
    # @param [Integer] cellspace Cellspace size
    def set_cell_space(cellspace)
      @cell_space = cellspace
    end
    alias :cell_space= :set_cell_space

    # Get space between grid cells (managed shapes).
    # @return [Integer] Cellspace size
    def get_cell_space
      @cell_space
    end
    alias :cell_space :get_cell_space
    
    # Iterate all cells. If a block is given passes row, col and shape (if any) for each cell to block.
    # Returns Enumerator if no block given.
    # @overload each_cell()
    #   @return [Enumerator]
    # @overload each_cell(&block)
    #   @yieldparam [Integer] row
    #   @yieldparam [Integer] col
    #   @yieldparam [shape,nil] shape
    #   @return [Object]
    def each_cell(&block)
      if block
        @rows.times do |row|
          @cols.times do |col|
            block.call(row, col, @cells[row*@cols + col])
          end
        end
      else
        ::Enumerator.new do |y|
          @rows.times do |row|
            @cols.times do |col|
              y << [row, col, @cells[row*@cols + col]]
            end
          end
        end
      end
    end

    # Clear the cell at given row and column index
    # @param [Integer] row
    # @param [Integer] col
    # @return [Boolean] true if cell existed, false otherwise
    # Note that this function doesn't remove managed (child) shapes from the parent grid shape
    # (they are still its child shapes but aren't managed anymore).
    def clear_cell(row, col)
      if row>=0 && row<@rows && col>=0 && col<@cols
        @cells[row*@cols + col] = nil
        true
      else
        false
      end
    end

    # Get managed shape specified by lexicographic cell index.
    # @overload get_managed_shape(index)
    #   @param [Integer] index Lexicographic index of requested shape
    #   @return [Shape, nil] shape object of given cell index if exists, otherwise nil
    # @overload get_managed_shape(row, col)
    #   @param [Integer] row Zero-base row index
    #   @param [Integer] col Zero-based column index
    #   @return [Shape, nil] shape object stored in specified grid cell if exists, otherwise nil
    def get_managed_shape(*args)
      index = args.size == 1 ? args.first : (args[0]*@cols)+args[1]
      @cells[index]
    end

    # Clear information about managed shapes and set number of rows and columns to zero.
    #
    # Note that this function doesn't remove managed (child) shapes from the parent grid shape
    # (they are still its child shapes but aren't managed anymore).
    def clear_grid
      @rows = @cols = 0
      @cells = []
    end

    # Append given shape to the grid at the last managed position.
    # @param [Shape] shape shape to append
    def append_to_grid(shape)
      row = @cells.size / @cols
      col = @cells.size - row*@cols

      insert_to_grid(row, col, shape)
    end

    # Insert given shape to the grid at the given position.
    # @overload insert_to_grid(row, col, shape)
    #   Note that the grid can grow in a vertical direction only, so if the user specifies a desired
    #   horizontal position bigger than the current number of columns is then this function exits with
    #   an error (false) return value. If specified vertical position exceeds the number or grid rows than
    #   the grid is resized. Any occupied grid cells at given position or beyond will be shifted to the next
    #   lexicographic position.
    #   @param [Integer] row Vertical position
    #   @param [Integer] col Horizontal position
    #   @param [Shape] shape shape to insert
    #   @return [Boolean] true on success, otherwise false
    # @overload insert_to_grid(index, shape)
    #   Note that the given index is a lexicographic position of inserted shape. The given shape is inserted before
    #   the existing item 'index', thus insert_to_grid(0, something) will insert an item in such way that it will become
    #   the first grid element. Any occupied grid cells at given position or beyond will be shifted to the next
    #   lexicographic position.
    #   @param [Integer] index Lexicographic position of inserted shape (>= 0)
    #   @param [Shape] shape shape to insert
    #   @return [Boolean] true on success, otherwise false
    def insert_to_grid(*args)
      if args.size > 2
        row, col, shape = args
        if shape && shape.is_a?(Shape) && is_child_accepted(shape.class)
          # protect duplicated occurrences
          return false if @cells.index(shape)

          # protect unbounded horizontal index (grid can grow in a vertical direction only)
          return false if col >= @cols
          # protect maximum rows
          return false if @max_rows > 0 && row >= @max_rows

          # add the shape to the children list if necessary
          unless @child_shapes.include?(shape)
            if @diagram
              @diagram.reparent_shape(shape, self)
            else
              shape.set_parent_shape(self)
            end
          end

          @cells.insert(row * @cols + col, shape)

          # adjust row count if necessary
          if @cells.size > cell_count
            update_rows
          end

          return true
        end
      else
        index, shape = args
        if shape && shape.is_a?(Shape) && is_child_accepted(shape.class)
          # protect duplicated occurrences
          return false if @cells.index(shape)

          # protect unbounded index
          return false if index < 0 || (@max_rows > 0 && index >= (@cols * @max_rows))

          # add the shape to the children list if necessary
          unless @child_shapes.include?(shape)
            if @diagram
              @diagram.reparent_shape(shape, self)
            else
              shape.set_parent_shape(self)
            end
          end

          @cells.insert(index, shape)

          # adjust row count if necessary
          if @cells.size > cell_count
            update_rows
          end

          return true
        end
      end
      false
    end

    # Remove given shape from the grid.
    # Shifts any occupied cells beyond the cell containing the given shape to the previous lexicographic position.
    # @param [Shape] shape shape which should be removed
    # @return [Shape,nil] removed shape or nil if not found
    # @note Note this does *not* remove the shape as a child shape.
    def remove_from_grid(shape)
      if @cells.delete(shape)
        # remove trailing empty cells
        @cells.pop until @cells.last
        # update row count
        @rows = @cells.size / @cols
        @rows += 1 if (@cells.size % @cols) > 0
        return shape
      end
      nil
    end

    # Update shape (align all child shapes and resize it to fit them)
    def update
      # check for existence of de-assigned shapes
      @cells.delete_if do |shape|
        shape && !@child_shapes.include?(shape)
      end

      # check whether all child shapes are present in the cells array...
      @child_shapes.each do |child|
        unless @cells.include?(child)
          # see if we can match the position of the new child with the position of another
          # (previously assigned) managed shape
          position_child_cell(child)
        end
      end

      # do self-alignment
      do_alignment
  
      # do alignment of shape's children
      do_children_layout
  
      # fit the shape to its children
      fit_to_children unless has_style?(STYLE::NO_FIT_TO_CHILDREN)
  
      # do it recursively on all parent shapes
      get_parent_shape.update if get_parent_shape
    end

    # Resize the shape to bound all child shapes. The function can be overridden if necessary.
    def fit_to_children
      # get bounding box of the shape and children set to be inside it
      abs_pos = get_absolute_position
      ch_bb = Wx::Rect.new(abs_pos.to_point, [0, 0])
  
      @child_shapes.each do |child|
        child.get_complete_bounding_box(ch_bb, BBMODE::SELF | BBMODE::CHILDREN) if child.has_style?(STYLE::ALWAYS_INSIDE)
      end
  
      # do not let the grid shape 'disappear' due to zero sizes...
      if (ch_bb.width == 0 || ch_bb.height == 0) && @cell_space == 0
        ch_bb.set_width(10)
        ch_bb.set_height(10)
      end
  
      @rect_size = Wx::RealPoint.new(ch_bb.width + 2*@cell_space, ch_bb.height + 2*@cell_space)
    end

    # Do layout of assigned child shapes
    def do_children_layout
      return if @cols == 0 || @rows == 0
  
      max_size = get_max_child_size

      @cells.each_with_index do |shape, i|
        if shape
          col = (i % @cols)
          row = (i / @cols)

          fit_shape_to_rect(shape, Wx::Rect.new(col*max_size.width + (col+1)*@cell_space,
                                                row*max_size.height + (row+1)*@cell_space,
                                                max_size.width, max_size.height))
        end
      end
    end

    # Event handler called when any shape is dropped above this shape (and the dropped
    # shape is accepted as a child of this shape). The function can be overridden if necessary.
    #
    # The function is called by the framework (by the shape canvas).
    # @param [Wx::RealPoint] _pos Relative position of dropped shape
    # @param [Shape] child dropped shape
    def on_child_dropped(_pos, child)
      # see if we can match the position of the new child with the position of another
      # (previously assigned) managed shape
      if child && !child.is_a?(LineShape)
        # insert child based on it's current (possibly dropped) position
        position_child_cell(child)
      end
    end

    protected

    # called after the shape has been newly imported/pasted/dropped
    # checks the cells for stale links
    def on_import
      # check for existence of non-included shapes
      @cells.delete_if do |shape|
        shape && !@child_shapes.include?(shape)
      end
    end

    # update row count
    def update_rows
      @rows = @cells.size / @cols
      @rows += 1 if (@cells.size % @cols) > 0
    end

    # returns maximum size of all managed (child) shapes
    # @return [Wx::Size]
    def get_max_child_size
      @child_shapes.inject(Wx::Size.new(0, 0)) do |max_size, shape|
        child_rect = shape.get_bounding_box

        max_size.set_width(child_rect.width) if shape.get_h_align != HALIGN::EXPAND && child_rect.width > max_size.width
        max_size.set_height(child_rect.height) if shape.get_v_align != VALIGN::EXPAND && child_rect.height > max_size.height
        max_size
      end
    end

    def find_cell(child_rect)
      max_size = get_max_child_size

      # find the cell index where the new or dragged child is positioned above and in front of
      offset = get_bounding_box.top_left
      cell_count.times.find do |cell|
        col = (cell % @cols)
        row = (cell / @cols)
        cell_rct = Wx::Rect.new(col*max_size.width + (col+1)*@cell_space,
                                row*max_size.height + (row+1)*@cell_space,
                                max_size.width, max_size.height).offset!(offset)
        child_rect.right <= cell_rct.right && child_rect.bottom <= cell_rct.bottom
      end
    end

    def position_child_cell(child)
      crct = child.get_bounding_box
      # if the child intersects this box shape we look
      # for the cell it should go into (if any)
      if @cells.size>0 && intersects?(crct)
        # find the cell index where the new child is positioned above and in front of
        index = find_cell(crct)
        # now see where to put the new/moved child
        if index    # found a matching cell?
          target_cell = @cells[index]
          # if the child being inserted already had a slot (moving a child)
          if (child_index = @cells.index(child))
            # if the newly found index equals the existing index there is nothing to do
            return if child_index == index
            # else remove the child from it's current position; this provides support for reordering child shapes by dragging
            remove_from_grid(child)
          end
          # insert/move the child
          if target_cell # is cell occupied?
            # if the child being moved was positioned before the new position we need to adjust the new position
            index -= 1 if child_index && child_index < index
          # else
          #   # move to empty cell
          #   @cells[index] = child
          end
          # insert
          insert_to_grid(index, child)
          return # done
        end
      end
      # otherwise append
      # remove child from current position if already part of grid
      remove_from_grid(child) if @cells.index(child)
      # append
      append_to_grid(child)
    end

    private

    # (de-)serialization only.

    # default deserialization finalizer
    def create
      update_rows
    end

    def get_cols
      @cols
    end
    def set_cols(num)
      @cols = num
    end

    def get_cells
      @cells
    end
    def set_cells(cells)
      @cells = cells
    end

  end

end
