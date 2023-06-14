# Wx::SF - layout algorithm classes
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  # Base class for all layouting algorithms. 
  class LayoutAlgorithm
    
    # Function performing the layout change. All derived classes must implement it.
    # @param [Array<Shape>] shapes List of shapes which should be layout-ed
    def do_layout(shapes)
      ::Kernel.raise NotImplementedError
    end
    
    protected
    
    # Calculate bounding box surrounding given shapes.
    # @param [Array<Shape>] shapes List of shapes
    # @return [Wx::Rect] Bounding box
    def get_bounding_box(shapes)
      shapes.inject(nil) do |rct_bb, shape|
        rct_bb ? rct_bb.union!(shape.get_bounding_box) : shape.get_bounding_box
      end
    end

    # Get overall extent of all given shapes calculated as a sum of their width and height.
    # @param [Array<Shape>] shapes List of shapes
    # @return [Wx::Size] Overall shapes extent
    def get_shapes_extent(shapes)
      shapes.inject(Wx::Size.new) do |ext_sz, shape|
        sh_bb = shape.get_bounding_box
        ext_sz.width += sh_bb.width
        ext_sz.height += sh_bb.height
        ext_sz
      end
    end

    # Get center point of given shapes.
    # @param [Array<Shape>] shapes List of shapes
    # @return [Wx::RealPoint] Center point
    def get_shapes_center(shapes)
      center = shapes.inject(Wx::RealPoint.new) do |centre, shape|
        sh_pos = shape.get_absolute_position
        centre.x += sh_pos.x
        centre.y += sh_pos.y
        centre
      end
      center.x /= shapes.size
      center.y /= shapes.size
      center
    end

    # Get top-left point of bounding box surrounding given shapes.
    # @param [Array<Shape>] shapes List of shapes
    # @return [Wx::RealPoint] Top-left point of bounding box surrounding given shapes
    def get_top_left(shapes)
      shapes.inject(Wx::RealPoint.new(::Float::MAX, ::Float::MAX)) do |pos, shape|
        sh_pos = shape.get_absolute_position
        pos.x = sh_pos.x if sh_pos.x < pos.x
        pos.y = sh_pos.y if sh_pos.y < pos.y
        pos
      end
    end

  end
  

  # pre-defined algorithms ###########################
  
  # Class encapsulating algorithm which layouts all top-most shapes into circle registered under "Circle" name.
  # The algorithm doesn't optimize connection lines crossing.
  class LayoutCircle < LayoutAlgorithm
    
    # Constructor.
    def initialize
      @distance_ratio = 1.0
    end

    # Get or set ratio in which calculated distance between shapes will be reduced. Values less than
    # 1 means that the distance will be smaller, values bigger than 1 means that the distance will be
    # bigger.
    attr_accessor :distance_ratio

    # Function performing the layout change.
    # @param [Array<Shape>] shapes List of shapes which should be layout-ed
    def do_layout(shapes)
      size_shapes = get_shapes_extent(shapes)
      center = get_shapes_center(shapes)

      # double x, y
      step = 360.0 / shapes.size
      degree = 0
      rx = (size_shapes.x / 2) * @distance_ratio
      ry = (size_shapes.y / 2) * @distance_ratio

      shapes.each do |shape|
        x = center.x + Math.cos(degree * Math::PI / 180 ) * rx
        y = center.y + Math.sin( degree * Math::PI / 180 ) * ry
        degree += step
        shape.move_to(x, y)
      end
    end

  end

  # Class encapsulating algorithm which layouts all top-most shapes into vertical tree registered under "Vertical Tree" name.
  class LayoutVerticalTree < LayoutAlgorithm

    # Constructor.
    def initialize
      @h_space = @v_space = 30.0
    end

    # Get or set horizontal space between shapes.
    attr_accessor :h_space

    # Get or set vertical space between shapes.
    attr_accessor :v_space

    # Function performing the layout change.
    # @param [Array<Shape>] shapes List of shapes which should be layout-ed
    def do_layout(shapes)
      start = get_top_left(shapes)
      min_x = start.x
      # find root items
      shapes.each do |shape|
        lst_connections = shape.get_assigned_connections(LineShape, Shape::CONNECTMODE::ENDING)

        min_x, _ = process_node(shape, start.y, min_x, 0) if lst_connections.empty?
      end
    end

    protected

    # Process single shape.
    # @param [Wx::Shape] node processed shape.
    # @param [Float] y Vertical position of the shape.
    # @param [Float] min_x
    # @param [Integer] curr_max_width
    # @return [Array(Float, Integer)]
    def process_node(node, y, min_x, curr_max_width)
      if node
        node.move_to(min_x, y)
        
        rct_bb = node.get_bounding_box
        curr_max_width = rct_bb.width if rct_bb.width > curr_max_width
        
        lst_neighbours = node.get_neighbours(Shape, Shape::CONNECTMODE::STARTING)
    
        if lst_neighbours.empty?
          min_x += curr_max_width + @h_space
        else
          lst_neighbours.each do |nbs|
            unless nbs.get_parent_shape
              min_x, curr_max_width = process_node(nbs, y + rct_bb.height + @v_space, min_x, curr_max_width)
            end
          end
        end
      end
      [min_x, curr_max_width]
    end

  end

  # Class encapsulating algorithm which layouts all top-most shapes into horizontal tree registered under "Horizontal Tree" name.
  class LayoutHorizontalTree < LayoutAlgorithm

    # Constructor.
    def initialize
      @h_space = @v_space = 30.0
    end

    # Get or set horizontal space between shapes.
    attr_accessor :h_space

    # Get or set vertical space between shapes.
    attr_accessor :v_space

    # Function performing the layout change.
    # @param [Array<Shape>] shapes List of shapes which should be layout-ed
    def do_layout(shapes)
      start = get_top_left(shapes)
      min_y = start.y
      # find root items
      shapes.each do |shape|
        lst_connections = shape.get_assigned_connections(LineShape, Shape::CONNECTMODE::ENDING)

        min_y, _ = process_node(shape, start.x, min_y, 0) if lst_connections.empty?
      end
    end

    protected

    # Process single shape.
    # @param [Wx::Shape] node processed shape.
    # @param [Float] x Vertical position of the shape.
    # @param [Float] min_y
    # @param [Integer] curr_max_height
    # @return [Array(Float, Integer)]
    def process_node(node, x, min_y, curr_max_height)
      if node
        node.move_to(x, min_y)

        rct_bb = node.get_bounding_box
        curr_max_height = rct_bb.height if rct_bb.height > curr_max_height

        lst_neighbours = node.get_neighbours(Shape, Shape::CONNECTMODE::STARTING)

        if lst_neighbours.empty?
          min_y += curr_max_height + @v_space
        else
          lst_neighbours.each do |nbs|
            unless nbs.get_parent_shape
              min_y, curr_max_height = process_node(nbs, x + rct_bb.width + @h_space, min_y, curr_max_height)
            end
          end
        end
      end
      [min_y, curr_max_height]
    end

  end

  # Class encapsulating algorithm which layouts all top-most shapes into mesh registered under "Mesh" name.
  # The algorithm doesn't optimize connection lines crossing.
  class LayoutMesh < LayoutAlgorithm

    # Constructor.
    def initialize
      @h_space = @v_space = 30.0
    end

    # Get or set horizontal space between shapes.
    attr_accessor :h_space

    # Get or set vertical space between shapes.
    attr_accessor :v_space

    # Function performing the layout change.
    # @param [Array<Shape>] shapes List of shapes which should be layout-ed
    def do_layout(shapes)
      cols = Math.sqrt(shapes.size).floor
      max_h = -@h_space
      roffset = coffset = 0

      start = get_top_left(shapes)

      shapes.each_with_index do |shape, i|
        if (i % cols) == 0
          coffset = 0
          roffset += max_h + @h_space
          max_h = 0
        end

        shape.move_to(start.x + coffset, start.y + roffset)

        rct_bb = shape.get_bounding_box
        coffset += rct_bb.width + @v_space

        max_h = rct_bb.height if rct_bb.height > max_h
      end
    end

  end

  # Module implements automatic diagram layout. The module allows to automatically layout shapes
  # included in diagram manager/shape canvas/list of shapes by using several pre-defined layouting
  # algorithms. The module should be used as it is.
  module AutoLayout

    class << self

      def layout_algorithms_table
        @layout_algorithms ||= {}
      end
      private :layout_algorithms_table

      def register_layout_algorithm(name, klass)
        layout_algorithms_table[name.to_s] = klass
      end

      def get_layout_algorithm(name)
        layout_algorithms_table.has_key?(name.to_s) ? layout_algorithms_table[name.to_s].new : nil
      end

      def layout_algorithms
        layout_algorithms_table.keys
      end

      def each_layout_algorithm(&block)
        if block
          layout_algorithms_table.each_value { |klass| block.call(klass.new) }
        else
          ::Enumerator.new { |y| layout_algorithms_table.each_value { |klass| y << klass.new } }
        end
      end

      # @overload layout(shapes, algname)
      #   Layout shapes included in given list.
      #   @param [Array<Shape>] shapes List of shapes
      #   @param [String] algname Algorithm name
      #   @return [Boolean] true if layout algorithm was found and executed, false otherwise
      # @overload layout(diagram, algname)
      #   Layout shapes included in given diagram.
      #   @param [Diagram] diagram Reference to diagram
      #   @param [String] algname Algorithm name
      #   @return [Boolean] true if layout algorithm was found and executed, false otherwise
      # @overload layout(canvas, algname)
      #   Layout shapes included in given shape canvas.
      #   @param [ShapeCanvas] canvas Reference to shape canvas
      #   @param [String] algname Algorithm name
      #   @return [Boolean] true if layout algorithm was found and executed, false otherwise
      def layout(shapes, algname)
        if shapes.is_a?(::Array)
          alg = get_layout_algorithm(algname)
          if alg
            shapes.first.get_diagram.set_modified unless shapes.empty? || shapes.first.get_diagram.nil?
            alg.do_layout(shapes)
            return true
          end
        elsif shapes.is_a?(Diagram) || shapes.is_a?(ShapeCanvas)
          alg = get_layout_algorithm(algname)
          if alg
            diagram = shapes.is_a?(Diagram) ? shapes : shapes.get_diagram
            # layout all top level shapes excluding the line shapes
            alg.do_layout(diagram.get_top_shapes.reject { |shp| shp.is_a?(LineShape) })
            diagram.move_shapes_from_negatives
            diagram.set_modified
            update_canvas(diagram.get_shape_canvas) if diagram.get_shape_canvas
            return true
          end
        else
          ::Kernel.raise ArgumentError, 'Expected array, diagram or canvas'
        end
        false
      end

      protected

      # Update given shape canvas.
      # @param [ShapeCanvas] canvas
      def update_canvas(canvas)
        canvas.center_shapes
        canvas.update_virtual_size
        canvas.update_multiedit_size
        canvas.refresh(false)
      end

    end

    register_layout_algorithm('Circle', LayoutCircle)
    register_layout_algorithm('Mesh', LayoutMesh)
    register_layout_algorithm('Horizontal Tree', LayoutHorizontalTree)
    register_layout_algorithm('Vertical Tree', LayoutVerticalTree)

  end

end
