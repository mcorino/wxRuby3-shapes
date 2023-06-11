# Wx::SF::Diagram - diagram class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'set'

require 'wx/shapes/serializable'
require 'wx/shapes/shape'
require 'wx/shapes/shape_canvas'

module Wx::SF

  INCLUDE_PARENTS = true
  WITHOUT_PARENTS = false
  INITIALIZE = true
  DONT_INITIALIZE = false

  class Diagram

    include Serializable

    property shapes: :serialize_shapes
    property :accepted_shapes, :accepted_top_shapes

    # Search mode flags for get_shape_at_position method
    SEARCHMODE = ShapeCanvas::SEARCHMODE

    def initialize
      @shapes = ShapeList.new
      @shape_canvas = nil
      @is_modified = false
      @accepted_shapes = ::Set.new(['*'])
      @accepted_top_shapes = ::Set.new(['*'])
    end

    # Returns the shape canvas.
    # @return [Wx::SF::ShapeCanvas]
    def get_shape_canvas
      @shape_canvas
    end
    alias :shape_canvas :get_shape_canvas

    # Set the shape canvas.
    # @param [Wx::SF::ShapeCanvas] canvas
    def set_shape_canvas(canvas)
      @shape_canvas = canvas
    end
    alias :shape_canvas= :set_shape_canvas

    # Get information about managed diagram's modification.
    #
    # The function returns TRUE if the diagram has been modified and its content
    # should be saved. The modification flag is cleared when the content is saved.
    # @return [Boolean] true if managed diagram is modified, otherwise false.
    def is_modified
      @is_modified
    end
    alias :modified? :is_modified

    # Set diagram's modification flag manually.
    # @param [Boolean] state State of diagram's modification flag.
    def set_modified(state = true)
      @is_modified = state
    end
    alias :modified= :set_modified

    # Create new direct connection between two shapes.
    #
    # This function creates new simple connection line (without arrows) between given
    # shapes.
    # @overload create_connection(src_id, trg_id, save_state = true)
    #   @param [Wx::Serializable::ID] src_id id of a source shape
    #   @param [Wx::Serializable::ID] trg_id id of target shape
    #   @param [Boolean] save_state set the parameter true if you wish to save canvas state after the operation
    #   @return [Array(Wx::SF::ERRCODE, Wx::SF::Shape)] operation result and new connection object. the object is added to the shape canvas automatically.
    # @overload create_connection(src_id, trg_id, line_info, save_state = true)
    #   @param [Wx::Serializable::ID] src_id id of a source shape
    #   @param [Wx::Serializable::ID] trg_id id of target shape
    #   @param [Class] line_info Connection type (any class inherited from Wx::SF::LineShape)
    #   @param [Boolean] save_state set the parameter true if you wish to save canvas state after the operation
    #   @return [Array(Wx::SF::ERRCODE, Wx::SF::Shape)] operation result and new connection object. the object is added to the shape canvas automatically.
    # @overload create_connection(src_id, trg_id, line, save_state = true)
    #   @param [Wx::Serializable::ID] src_id id of a source shape
    #   @param [Wx::Serializable::ID] trg_id id of target shape
    #   @param [Wx::SF::LineShape] line the line shape
    #   @param [Boolean] save_state set the parameter true if you wish to save canvas state after the operation
    #   @return [Array(Wx::SF::ERRCODE, Wx::SF::Shape)] operation result and new connection object. the object is added to the shape canvas automatically.
    # @see start_interactive_connection
    def create_connection(src_id, trg_id, *rest)
      err = shape = nil
      if rest.first.is_a?(LineShape)
        line = rest.shift
        save_state = rest.empty? ? true : rest.shift
        err = add_shape(line, nil, Wx::DEFAULT_POSITION, INITIALIZE, DONT_SAVE_STATE)
        shape = line if err == ERRCODE::OK
      else
        line_type = (rest.empty? || !rest.first.is_a?(::Class)) ? LineShape : rest.shift
        save_state = rest.empty? ? true : rest.shift
        err, shape = create_shape(line_type, DONT_SAVE_STATE)
      end
      if shape
        shape.set_src_shape_id(src_id)
        shape.set_trg_shape_id(trg_id)

        if @shape_canvas
          @shape_canvas.save_canvas_state if save_state
          shape.refresh
        end
      end
      [err, shape]
    end

    # Create new shape and add it to the shape canvas.
    # @overload create_shape(shape_info, save_state = true)
    #   @param [Class] shape_info Shape type
    #   @param [Boolean] save_state Set the parameter true if you wish to save canvas state after the operation
    #   @return [Array(Wx::SF::ERRCODE, Wx::SF::Shape)] operation result and new shape. the object is added to the shape canvas automatically.
    # @overload create_shape(shape_info, pos, save_state = true)
    #   @param [Class] shape_info Shape type
    #   @param [Wx::Point] pos shape position
    #   @param [Boolean] save_state Set the parameter true if you wish to save canvas state after the operation
    #   @return [Array(Wx::SF::ERRCODE, Wx::SF::Shape)] operation result and new shape. the object is added to the shape canvas automatically.
    def create_shape(shape_info, *rest)
      pos = if rest.first.is_a?(Wx::Point)
              rest.shift
            elsif @shape_canvas
              clt_rect = @shape_canvas.get_client_rect
              Wx::Point.new((clt_rect.right - clt_rect.left)/2,
                            (clt_rect.bottom - clt_rect.top)/2)
            else
              Wx::Point.new
            end
      save_state = rest.empty? ? true : rest.shift
      if shape_info && is_shape_accepted(shape_info)
        # create shape object from class info
        shape = shape_info.new

        parent_shape = nil
        # update given position
        lpos = pos;
        lpos = @shape_canvas.fit_position_to_grid(@shape_canvas.dp2lp(pos)) if @shape_canvas
        # line shapes can be assigned to root only
        parent_shape = get_shape_at_position(lpos) unless shape.is_a?(LineShape)

        if parent_shape && parent_shape.is_child_accepted(shape_info)
          err = add_shape(shape, parent_shape, pos - parent_shape.get_absolute_position.to_point, INITIALIZE, save_state)
        else
          err = add_shape(shape, nil, pos, INITIALIZE, save_state)
        end

        parent_shape.update if parent_shape

        [err, shape]
      else
        [ERRCODE::NOT_ACCEPTED, nil]
      end
    end

    # Add an existing shape to the canvas.
    # @param [Wx::SF::Shape] shape new shape
    # @param [Wx::SF::Shape] parent the parent shape
    # @param [Wx::Point] pos shape position
    # @param [Boolean] initialize true if the shape should be reinitialized, otherwise false
    # @param [Boolean] save_state true if the canvas state should be saved
    # @return [Wx::SF::ERRCODE] operation result
    def add_shape(shape, parent,  pos, initialize, save_state = true)
      if shape
        if shape.is_a?(Shape) && is_shape_accepted(shape.class)
          if @shape_canvas
            new_pos = @shape_canvas.fit_position_to_grid(@shape_canvas.dp2lp(pos))
            shape.set_relative_position(new_pos.to_real)
          else
            shape.set_relative_position(pos.to_real)
          end

          # add shape
          if parent
            shape.set_parent_shape(parent)
          else
            if is_top_shape_accepted(shape.class)
              @shapes << shape
              shape.set_diagram(self)
            else
              return ERRCODE::NOT_ACCEPTED
            end
          end

          # initialize added shape
          if initialize
            shape.create_handles

            shape.set_hover_colour(@shape_canvas.get_hover_colour) if @shape_canvas

            if has_children(shape)
                # get shape's children (if exist)
                lst_children = shape.get_child_shapes(ANY, RECURSIVE)
                # initialize shape's children
                lst_children.each do |child|
                  child.create_handles
                  child.update

                  child.set_hover_colour(@shape_canvas.get_hover_colour) if @shape_canvas
                end
            end
          end

          # reset scale of assigned shape canvas (if exists and it is necessary...)
          if @shape_canvas && shape.is_a?(ControlShape)
            @shape_canvas.set_scale(1.0)
          end

          @shape_canvas.save_canvas_state if @shape_canvas && save_state

          @is_modified = true

          ERRCODE::OK
        else
          ERRCODE::NOT_ACCEPTED
        end
      else
        ERRCODE::INVALID_INPUT
      end
    end

    # Remove given shape from the shape canvas.
    # @param [Wx::SF::Shape] shape shape object that should be deleted
    # @param [Boolean] refresh Set the parameter to true if you wish to repaint the canvas
    def remove_shape(shape, refresh = true)
      return unless shape

      parent = shape.get_parent_shape

      # get all shape's children
      lst_children = shape.get_child_shapes(ANY, RECURSIVE)
      lst_children << shape # and shape itself

      # retrieve all assigned lines
      lst_connections = []
      lst_children.each do |child|
        get_assigned_connections(child, LineShape, Shape::CONNECTMODE::BOTH, lst_connections)
      end

      # remove all assigned lines
      lst_removed_connections = []
      lst_connections.each do |line|
        # one connection may be used by the parent and also by his child
        unless lst_removed_connections.include?(line)
          lst_removed_connections << line
          remove_shape(line,false)
        end
      end

      # remove the shape and it's children from canvas cache and shape index list
      lst_children.each do |child|
        @shape_canvas.send(:remove_from_temporaries, shape) if @shape_canvas
      end

      # remove the shape
      shape.set_parent_shape(nil) # also removes shape from parent if it had a parent
      shape.set_diagram(nil)
      @shapes.delete(shape)

      @is_modified = true

      parent.update if parent

      @shape_canvas.refresh(false) if refresh && @shape_canvas
    end

    # Remove shapes from the shape canvas
    # @param [Array<Wx::SF::Shape>] selection List of shapes which should be removed from the canvas
    def remove_shapes(selection)
      selection.each { |shape| remove_shape(shape, false) if contains?(shape) }
    end

    # Change shape's parent (possibly making it unparented i.e. toplevel)
    # @param [Wx::SF::Shape] shape shape to reparent
    # @param [Wx::SF::Shape,nil] parent new parent or nil
    # @return [Wx::SF::Shape] re-parented shape
    def reparent_shape(shape, parent)
      prev_parent = shape.get_parent_shape
      if prev_parent.nil? && parent
        @shapes.delete(shape) # remove from top level list if the shape will become parented
      elsif prev_parent && parent.nil?
        @shapes << shape # add to toplevel shapes if the shape will become unparented
        shape.set_diagram(self) # make sure the right diagram is set
      end
      shape.set_parent_shape(parent)
      shape
    end

    # Returns true if the given shape is part of the diagram, false otherwise
    # @param [Wx::SF::Shape] shape
    # @return [Boolean]
    def contains_shape(shape)
      @shapes.include?(shape.id,true)
    end
    alias :contains_shape? :contains_shape
    alias :contains? :contains_shape

    # Remove all shapes from canvas
    def clear
      @shapes.clear
      if @shape_canvas
        @shape_canvas.get_multiselection_box.show(false)
        @shape_canvas.update_virtual_size
      end
    end

    # Move given shape to the end of the shapes list
    # @param [Wx::SF::Shape] shape
    def move_to_end(shape)
      if (a_shape = @shapes.delete(shape))
        @shapes << a_shape
      end
    end

    # Move all shapes so none of it will be located in negative position
    def move_shapes_from_negatives
      min_x = min_y = 0.0
    
      # find the maximal negative position value
      shapes = get_shapes
    
      shapes.each_with_index do |shape, ix|
        shape_pos = shape.get_absolute_position
        if ix == 0
          min_x = shape_pos.x
          min_y = shape_pos.y
        else
          min_x = shape_pos.x if shape_pos.x < min_x
          min_y = shape_pos.y if shape_pos.y < min_y
        end
      end
    
      # move all parents shape so they (and their children) will be located in the positive values only
      if min_x < 0.0 || min_y < 0.0
        shapes.each do |shape|
          unless shape.get_parent_shape
            shape.move_by(min_x.to_i.abs, 0) if min_x < 0.0
            shape.move_by(0, min_y.to_i.abs) if min_y < 0.0
          end
        end
      end
    end

    # Update all shapes in the diagram manager
    def update_all
      get_shapes.each { |shape| shape.update unless shape.has_children? }
    end
    
    # Add given shape type to an acceptance list. The acceptance list contains class
    # names of the shapes which can be inserted into this instance of shapes canvas.
    # Note: Keyword 'All' behaves like any class name.
    # @param [String,Class] type Class (name) of accepted shape object
    # @see is_shape_accepted
    def accept_shape(type)
      @accepted_shapes << type.to_s
    end

    # Tells whether the given shape type is accepted by this canvas instance (it means
    # whether this shape can be inserted into it).
    #
    # The function is typically used by the framework for determination whether class type supplied
    # by add_shape or create_shape function can be inserted into shape canvas.
    # @param [String,Class] type Class (name) of examined shape object
    # @return [Boolean] true if the shape type is accepted, otherwise false.
    def is_shape_accepted(type)
      @accepted_shapes.include?(type.to_s) || @accepted_shapes.include?('*')
    end
    alias :shape_accepted? :is_shape_accepted

	  # Clear shape object acceptance list
	  # @see accept_shape
    def clear_accepted_shapes
      @accepted_shapes.clear
    end

	  # Get reference to shape acceptance list
    # @return [Set<String>]
    def get_accepted_shapes
      @accepted_shapes
    end
    alias :accepted_shapes :get_accepted_shapes

    # Add given shape type to list of accepted top shapes. The acceptance list contains class
    # names of the shapes which can be inserted into this instance of shapes canvas as a shape without
	  # any parent (i.e. shape placed directly onto the canvas).
    # Note: Keyword '*' behaves like any class name.
    # @param [String,Class] type Class (name) of accepted shape object
    # @see is_top_shape_accepted
    def accept_top_shape(type)
      @accepted_top_shapes << type.to_s
    end

    # Tells whether the given shape type is accepted by this canvas instance as a top shape
	  # (it means whether this shape can be inserted directly into it without any parent).
    #
    # The function is typically used by the framework for determination whether class type supplied
    # by add_shape or create_shape function can be inserted directly onto shape canvas.
    # @param [String,Class] type Class (name) of examined shape object
    # @return [Boolean] true if the shape type is accepted, otherwise false.
    def is_top_shape_accepted(type)
      @accepted_top_shapes.include?(type.to_s) || @accepted_top_shapes.include?('*')
    end
    alias :top_shape_accepted? :is_top_shape_accepted

	  # Clear top shapes acceptance list
	  # @see accept_shape
    def clear_accepted_top_shapes
      @accepted_top_shapes.clear
    end

	  # Get reference to top shapes acceptance list
    # @return [Set<String>]
    def get_accepted_top_shapes
      @accepted_top_shapes
    end
    alias :accepted_top_shapes :get_accepted_top_shapes

    # Find shape with given ID.
    # @param [Wx::SF::Serializable::ID] id Shape's ID
    # @return [Wx::SF::Shape] shape if exists, otherwise nil
    def find_shape(id)
      @shapes.get(id, true)
    end

	  # Get list of connections assigned to given parent shape.
	  # @param [Wx::SF::Shape] parent parent shape
	  # @param [Class] shape_info Line object type
	  # @param [Wx::SF::Shape::CONNECTMODE] mode Search mode
	  # @param [Array<Wx::SF::Shape>] lines shape list where all found connections will be stored
    # @return [Array<Wx::SF::Shape>] shape list
	  # @see Wx::SF::Shape::CONNECTMODE
    def get_assigned_connections(parent, shape_info, mode, lines = [])
      return unless parent && parent.get_id

      # lines are all toplevel so we do not have to search recursively...
      lst_lines = @shapes.select { |shape| shape.is_a?(shape_info) }

      lst_lines.each do |line|
        case mode
        when Shape::CONNECTMODE::STARTING
          lines << line if line.get_src_shape_id == parent.get_id
        when Shape::CONNECTMODE::ENDING
          lines << line if line.get_trg_shape_id == parent.get_id
        when Shape::CONNECTMODE::BOTH
          lines << line if line.get_src_shape_id == parent.get_id || line.get_trg_shape_id == parent.get_id
        end
      end
      lines
    end

    # Returns the list of top level shapes
    def get_top_shapes
      @shapes
    end

    def get_all_shapes
      @shapes.all
    end

	  # Get list of shapes of given type.
    # @param [Class] shape_info Line object type
	  # @param [Shape::SEARCHMODE] mode Search algorithm
    # @param [Array<Wx::SF::Shape>] shapes shape list where all found shapes will be stored
    # @return [Array<Wx::SF::Shape>] shape list
	  # @see Shape::SEARCHMODE
    def get_shapes(shape_info = Wx::SF::Shape, mode = Shape::SEARCHMODE::BFS, shapes = [])
      @shapes.each do |shape|
        shapes << shape if shape.is_a?(shape_info)
        shape.get_children_recursively(shape_info, mode, shapes) if mode == Shape::SEARCHMODE::DFS
      end
      if mode == Shape::SEARCHMODE::BFS
        @shapes.each { |shape| shape.get_children_recursively(shape_info, mode, shapes) }
      end
      shapes
    end

	  # Get shape at given logical position
	  # @param [Wx::Point] pos Logical position
	  # @param [Integer] zorder Z-order of searched shape (useful if several shapes are located at the given position)
	  # @param [SEARCHMODE] mode Search mode
	  # @return [Wx::SF::Shape] shape if found, otherwise nil
	  # @see SEARCHMODE
    # @see Wx::SF::ShapeCanvas::dp2lp
    # @see Wx::SF::ShapeCanvas#get_shape_under_cursor
    def get_shape_at_position(pos, zorder = 1, mode = SEARCHMODE::BOTH)
      # sort shapes list in the way that the line shapes will be at the top of the list
      # and all non-line shapes get listed in reversed order as returned from get_shapes (for z order)
      ins_pos = 0
      shapes = get_shapes.inject([]) do |list, shape|
        if shape.is_a?(LineShape)
          list.prepend(shape)
          ins_pos += 1
        else
          list.insert(ins_pos, shape)
        end
        list
      end
      # find the topmost shape according to the given rules
      counter = 1
      shapes.each do |shape|
        if shape.visible? && shape.active? && shape.contains?(pos)
          case mode
          when SEARCHMODE::SELECTED
            if shape.selected?
              return shape if counter == zorder
              counter += 1
            end
          when SEARCHMODE::UNSELECTED
            unless shape.selected?
              return shape if counter == zorder
              counter += 1
            end
          when SEARCHMODE::BOTH
            return shape if counter == zorder
            counter += 1
          end
        end
      end

      nil
    end

	  # Get list of all shapes located at given position
    # @param [Wx::Point] pos Logical position
    # @param [Array<Wx::SF::Shape>] shapes shape list where all found shapes will be stored
    # @return [Array<Wx::SF::Shape>] shape list
    # @see Wx::SF::ShapeCanvas::dp2lp
    def get_shapes_at_position(pos, shapes = [])
      get_shapes.each do |shape|
        shapes << shape if shape.visible? && shape.active? && shape.contains?(pos)
      end
    end

	  # Get list of shapes located inside given rectangle
	  # @param [Wx::Rect] rct Examined rectangle
    # @param [Array<Wx::SF::Shape>] shapes shape list where all found shapes will be stored
    # @return [Array<Wx::SF::Shape>] shape list
    def get_shapes_inside(rct, shapes = [])
      get_shapes.each do |shape|
        shapes << shape if shape.visible? && shape.active? && shape.intersects?(rct)
      end
    end

	  # Determines whether the diagram contains some shapes.
	  # @return true if there are no shapes in the diagram, otherwise false
    def is_empty
      @shapes.empty?
    end
    alias :empty? :is_empty

    # Function finds out whether given shape has some children.
    # @param [Wx::SF::Shape] parent potential parent shape
    # @return [Boolean] true if the parent shape has children, otherwise false
    def has_children(parent)
      parent.has_children?
    end
    alias :has_children? :has_children
    
    # Get neighbour shapes connected to given parent shape.
	  # @param [Wx::SF::Shape] parent parent shape (can be nil for all topmost shapes)
	  # @param [Class] shape_info Line object type
	  # @param [Wx::SF::Shape::CONNECTMODE] condir Connection direction
	  # @param [Boolean] direct set this flag to true if only closest shapes should be found
    # otherwise also shapes connected by forked lines will be found (also
    # constants DIRECT and INDIRECT can be used)
    # @param [Array<Wx::SF::Shape>] neighbours List to add neighbour shapes to
    # @return [Array<Wx::SF::Shape>] shape list
    # @see Wx::SF::Shape::CONNECTMODE
    def get_neighbours(parent, shape_info, condir, direct = true, neighbours = [])
      if parent
        parent.get_neighbours(shape_info, condir, direct, neighbours)
      else
        @shapes.each do |shape|
          shape.get_neighbours(shape_info, condir, direct, neighbours)
        end
      end
    end

    private

    # Update connection shapes after importing/dropping of new shapes
    def check_new_shapes(new_shapes)
      # deserializing will create unique ids synchronized across all deserialized shapes
      # lines and both connected shapes should have matching ids
      # we will remove any lines for which one or both connected shapes are missing (not copied)
      new_shapes.select! do |shape|
        if shape.is_a?(LineShape)
          # so that lines with both connected shapes will have matching ids
          # we will remove any lines for which one or both connected shapes are missing (not copied)
          if @shapes.include?(shape.get_src_shape_id) && @shapes.include?(shape.get_trg_shape_id)
            shape.create_handles
            true # keep
          else
            # remove from diagram
            @shapes.delete(shape)
            false # remove from new_shapes
          end
        else
          true # keep
        end
      end
      # deserializing will create unique ids synchronized across all deserialized shapes
      # so that grids and shapes linked to it's cells should have matching ids
      # we will clear any cells for which shapes are missing (not copied)
      update_grids(new_shapes) unless new_shapes.empty?
    end

    # Update grid shapes after importing/dropping of new shapes
    def update_grids(new_shapes)
      # deserializing will create unique ids synchronized across all deserialized shapes
      # so that grids and shapes linked to it's cells will have matching ids
      # we will clear any cells for which shapes are missing (not copied)
      new_shapes.each do |shape|
        if shape.is_a?(GridShape)
          grid.each_cell do |row, col, id|
            grid.clear_cell(row, col) unless id.nil? || @shapes.include?(id)
          end
        elsif shape.has_children?
          shape.get_children_recursively(nil, Shape::SEARCHMODE::DFS).each do |child|
            if shape.is_a?(GridShape)
              grid.each_cell do |row, col, id|
                grid.clear_cell(row, col) unless id.nil? || @shapes.include?(id)
              end
            end
          end
        end
      end
    end

    # Shape lis (de-)serialization
    def serialize_shapes(*arg)
      unless arg.empty?
        @shapes = arg.shift
        @shapes.each { |shape| shape.set_diagram(self) }
      end
      @shapes
    end

    # Set accepted shapes. Deserialization only.
    # @param [Array<String>] shp_names
    def set_accepted_shapes(shp_names)
      @accepted_shapes.merge(shp_names)
    end

    # Set accepted top shapes. Deserialization only.
    # @param [Array<String>] shp_names
    def set_accepted_top_shapes(shp_names)
      @accepted_top_shapes.merge(shp_names)
    end

    public def inspect
      "#<Wx::SF::Diagram:#{object_id}>"
    end

  end

end
