# Wx::SF::TextShape - grid shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'

module Wx::SF
  
  # Class encapsulates a rectangular shape derived from Wx::SF::RectShape class which acts as a grid-based
  # container able to manage other assigned child shapes (it can control their position). The managed
  # shapes are aligned into defined grid with a behaviour similar to classic Wx::GridSizer class.
  class GridShape < RectShape

    # default values
    module DEFAULT
      # Default value of GridShape @rows data member.
      ROWS = 3
      # Default value of GridShape @cols data member.
      COLS  = 3
      # Default value of GridShape @cell_space data member.
      CELLSPACE  = 5
    end
    
    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, rows, cols, cell_space, diagram)
    #   User constructor.
    #   @param [Wx::Point] pos Initial position
    #   @param [Wx::Size] size Initial size
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
        pos, size, @rows, @cols, @cell_space, diagram = args
        super(pos, size, diagram)
      end
      @cells = Array.new(@rows * @cols)
    end

    # Iterate all cells. If a block is given passes row, col and id for each cell to block.
    # Returns Enumerator if no block given.
    # @overload each_cell()
    #   @return [Enumerator]
    # @overload each_cell(&block)
    #   @yieldparam [Integer] row
    #   @yieldparam [Integer] col
    #   @yieldparam [Wx::SF::Serializable::ID,nil] id
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

    def clear_cell(row, col)
      if row>=0 && row<@rows && col>=0 && col<@cols
        @cells[row*@cols + col] = nil
      end
    end

    def get_cell(row, col)
      if row>=0 && row<@rows && col>=0 && col<@cols
        @cells[row*@cols + col]
      end
    end

  end

end
