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
      # Default value of GridShape @rows data member.
      ROWS = 3
      # Default value of GridShape @cols data member.
      COLS  = 3
      # Default value of GridShape @cell_space data member.
      CELLSPACE  = 5
    end

    property :rows, :cols, :cell_space, :cells

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
      if args.empty?
        super()
        @rows = DEFAULT::ROWS
        @cols = DEFAULT::COLS
        @cell_space = DEFAULT::CELLSPACE
      else
        pos, size, rows, cols, cell_space, diagram = args
        super(pos, size, diagram)
        @rows = rows || 0
        @cols = cols || 0
        @cell_space = cell_space || 0
      end
      @cells = []
      remove_style(Shape::STYLE::SIZE_CHANGE)
    end

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
    
    # Iterate all cells. If a block is given passes row, col and id for each cell to block.
    # Returns Enumerator if no block given.
    # @overload each_cell()
    #   @return [Enumerator]
    # @overload each_cell(&block)
    #   @yieldparam [Integer] row
    #   @yieldparam [Integer] col
    #   @yieldparam [FIRM::Serializable::ID,nil] id
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

    # Get the shape Id stored in cell at given row and column index
    # @param [Integer] row
    # @param [Integer] col
    # @return [FIRM::Serializable::ID, nil] id if cell exists and not empty, nil otherwise
    def get_cell(row, col)
      if row>=0 && row<@rows && col>=0 && col<@cols
        @cells[row*@cols + col]
      else
        nil
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
      if index>=0 && index<@cells.size && @cells[index]
        return @child_shapes.find { |child| @cells[index] == child.id }
      end
      nil
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
    #   @param [Integer] index Lexicographic position of inserted shape
    #   @param [Shape] shape shape to insert
    #   @return [Boolean] true on success, otherwise false
    def insert_to_grid(*args)
      if args.size > 2
        row, col, shape = args
        if shape && shape.is_a?(Shape) && is_child_accepted(shape.class)
          # protect duplicated occurrences
          return false if @cells.index(shape.id)

          # protect unbounded horizontal index (grid can grow in a vertical direction only)
          return false if col >= @cols

          # add the shape to the children list if necessary
          unless @child_shapes.include?(shape)
            if @diagram
              @diagram.reparent_shape(shape, self)
            else
              shape.set_parent_shape(self)
            end
          end

          @cells.insert(row * @cols + col, shape.id)

          # adjust row count if necessary
          if @cells.size > (@rows * @cols)
            @rows = @cells.size / @cols
          end

          return true
        end
      else
        index, shape = args
        if shape && shape.is_a?(Shape) && is_child_accepted(shape.class)
          # protect duplicated occurrences
          return false if @cells.index(shape.id)

          # protect unbounded index
          return false if index >= (@rows * @cols)

          # add the shape to the children list if necessary
          unless @child_shapes.include?(shape)
            if @diagram
              @diagram.reparent_shape(shape, self)
            else
              shape.set_parent_shape(self)
            end
          end

          @cells.insert(index, shape.id)

          # adjust row count if necessary
          if @cells.size > (@rows * @cols)
            @rows = @cells.size / @cols
          end

          return true
        end
      end
      false
    end

    # Remove shape with given ID from the grid.
    # Shifts any occupied cells beyond the cell containing the given id to the previous lexicographic position.
    # @param [FIRM::Serializable::ID] id ID of shape which should be removed
    # @note Note this does *not* remove the shape as a child shape.
    def remove_from_grid(id)
      @cells.delete(id)
    end

    # Update shape (align all child shapes and resize it to fit them)
    def update
      # check for existence of de-assigned shapes
      @cells.delete_if do |id|
        @child_shapes.find { |child| child.id == id }.nil?
      end

      # check whether all child shapes' IDs are present in the cells array...
      @child_shapes.each do |child|
        unless @cells.include?(child.id)
          # see if we can match the position of the new child with the position of another
          # (previously assigned) managed shape
          find_child_cell(child)
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
  
      max_rect = Wx::Rect.new(0,0,0,0)
  
      # get maximum size of all managed (child) shapes
      @child_shapes.each do |shape|
        curr_rect = shape.get_bounding_box

        max_rect.set_width(curr_rect.width) if shape.get_h_align != HALIGN::EXPAND && curr_rect.width > max_rect.width
        max_rect.set_height(curr_rect.height) if shape.get_v_align != VALIGN::EXPAND && curr_rect.height > max_rect.height
      end

      @cells.each_with_index do |id, i|
        if id
          shape = @child_shapes[id]
          col = (i % @cols)
          row = (i / @cols)

          fit_shape_to_rect(shape, Wx::Rect.new(col*max_rect.width + (col+1)*@cell_space,
                                                row*max_rect.height + (row+1)*@cell_space,
                                                max_rect.width, max_rect.height))
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
      append_to_grid(child) if child && !child.is_a?(LineShape)
      # see if we can match the position of the new child with the position of another
      # (previously assigned) managed shape
      if child && !child.is_a?(LineShape)
        # if the child already had a slot
        if @cells.index(child.id)
          # remove it from there; this provides support for reordering child shapes by dragging
          remove_from_grid(child.id)
        end

        # insert child based on it's current (possibly dropped) position
        find_child_cell(child)
      end
    end

    protected

    # called after the shape has been newly imported/pasted/dropped
    # checks the cells for stale links
    def on_import
      # check for existence of non-included shapes
      @cells.delete_if do |id|
        @child_shapes.find { |child| child.id == id }.nil?
      end
    end

    def find_child_cell(child)
      crct = child.get_bounding_box
      # if the child intersects this box shape we look
      # for the cell it should go into (if any)
      if @cells.size>0 && intersects?(crct)

        max_rect = Wx::Rect.new(0,0,0,0)
        # get maximum size of all managed (child) shapes
        @cells.each do |id|
          shape = id ? @child_shapes[id] : nil
          if shape
            curr_rect = shape.get_bounding_box

            max_rect.set_width(curr_rect.width) if shape.get_h_align != HALIGN::EXPAND && curr_rect.width > max_rect.width
            max_rect.set_height(curr_rect.height) if shape.get_v_align != VALIGN::EXPAND && curr_rect.height > max_rect.height
          end
        end

        # find the cell where the new child is positioned above and in front of
        inserted = false
        offset = get_bounding_box.top_left
        @cells.each_index do |cell|
          col = (cell % @cols)
          row = (cell / @cols)

          cell_rct = Wx::Rect.new(col*max_rect.width + (col+1)*@cell_space,
                                  row*max_rect.height + (row+1)*@cell_space,
                                  max_rect.width, max_rect.height).offset!(offset)
          if crct.right <= cell_rct.right && crct.bottom <= cell_rct.bottom
            if @cells[cell] # is cell occupied?
              # insert and shift other cells
              @cells.insert(cell, child.id)
              # adjust row count if necessary
              if @cells.size > (@rows * @cols)
                @rows = @cells.size / @cols
              end
            else
              # use empty cell
              @cells[cell] = child.id
            end
            inserted = true
            break
          end
        end
        return if inserted
      end
      # otherwise append
      @cells << child.id
      # adjust row count if necessary
      if @cells.size > (@rows * @cols)
        @rows = @cells.size / @cols
      end
    end

    private

    # Deserialization only.

    def get_rows
      @rows
    end
    def set_rows(num)
      @rows = num
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
