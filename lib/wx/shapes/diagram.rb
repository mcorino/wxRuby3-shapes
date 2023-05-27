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

    property :shapes

    # Search mode flags for get_shape_at_position method
    class SEARCHMODE < Wx::Enum
      # Search for selected shapes only
      SELECTED = self.new(0)
      # Search for unselected shapes only
      UNSELECTED = self.new(1)
      # Search for both selected and unselected shapes
      BOTH = self.new(2)
    end

    def initialize
      @shapes = []
      @shapes_index = {}
      @shape_canvas = nil
      @is_modified = false
      @accepted_shapes = ::Set.new
      @accepted_top_shapes = ::Set.new
    end

    attr_accessor :shape_canvas

    def get_shapes; @shapes; end
    private :get_shapes

    def set_shapes(list)
      @shapes.replace(list)
      @shapes_index.clear
      @shapes.each { |sh| @shapes_index[sh.id] = sh }
    end
    private :set_shapes

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

    end

    # Create new shape and add it to the shape canvas.
    # @overload create_shape(shape_info, save_state = true)
    #   @param [Class] shape_info Shape type
    #   @param [Boolean] save_state Set the parameter true if you wish to save canvas state after the operation
    #   @return [Array(Wx::SF::ERRCODE, Wx::SF::Shape)] operation result and new shape. the object is added to the shape canvas automatically.
    # @overload add_shape(shape_info, pos, save_state = true)
    #   @param [Class] shape_info Shape type
    #   @param [Wx::Point] pos shape position
    #   @param [Boolean] save_state Set the parameter true if you wish to save canvas state after the operation
    #   @return [Array(Wx::SF::ERRCODE, Wx::SF::Shape)] operation result and new shape. the object is added to the shape canvas automatically.
    def create_shape(shape_info, *rest)

    end

    # Add an existing shape to the canvas.
    # @param [Wx::SF::Shape] shape new shape
    # @param [Wx::SF::Shape] parent the parent shape
    # @param [Wx::Point] pos shape position
    # @param [Boolean] initialize true if the shape should be reinitialized, otherwise false
    # @param [Boolean] save_state true if the canvas state should be saved
    # @return [Wx::SF::ERRCODE] operation result
    def add_shape(shape, parent,  pos, initialize, save_state = true)

    end

    # Remove given shape from the shape canvas.
    # @param [Wx::SF::Shape] shape shape object that should be deleted
    # @param [Boolean] refresh Set the parameter to true if you wish to repaint the canvas
    def remove_shape(shape, refresh = true)

    end

    # Remove shapes from the shape canvas
    # @param [Array<Wx::SF::Shape>] selection List of shapes which should be removed from the canvas
    def remove_shapes(selection)

    end

    # Remove all shapes from canvas
    def clear

    end

    # Move all shapes so none of it will be located in negative position
    def move_shapes_from_negatives

    end

    # Update all shapes in the diagram manager
    def update_all

    end
    
    # Add given shape type to an acceptance list. The acceptance list contains class
    # names of the shapes which can be inserted into this instance of shapes canvas.
    # Note: Keyword 'All' behaves like any class name.
    # @param [String] type Class name of accepted shape object
    # @see is_shape_accepted
    def accept_shape(type)

    end

    # Tells whether the given shape type is accepted by this canvas instance (it means
    # whether this shape can be inserted into it).
    #
    # The function is typically used by the framework for determination whether class type supplied
    # by add_shape or create_shape function can be inserted into shape canvas.
    # @param [String] type Class name of examined shape object
    # @return [Boolean] true if the shape type is accepted, otherwise false.
    def is_shape_accepted(type)

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
    # @param [String] type Class name of accepted shape object
    # @see is_top_shape_accepted
    def accept_top_shape(type)

    end

    # Tells whether the given shape type is accepted by this canvas instance as a top shape
	  # (it means whether this shape can be inserted directly into it without any parent).
    #
    # The function is typically used by the framework for determination whether class type supplied
    # by add_shape or create_shape function can be inserted directly onto shape canvas.
    # @param [String] type Class name of examined shape object
    # @return [Boolean] true if the shape type is accepted, otherwise false.
    def is_top_shape_accepted(type)

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

    end

	  # Get list of connections assigned to given parent shape.
	  # @param [Wx::SF::Shape] parent parent shape
	  # @param [Class] shape_info Line object type
	  # @param [Wx::SF::Shape::CONNECTMODE] mode Search mode
	  # @param [Array<Wx::SF::Shape>] lines shape list where all found connections will be stored
    # @return [Array<Wx::SF::Shape>] shape list
	  # @see Wx::SF::Shape::CONNECTMODE
    def get_assigned_connections(parent, shape_info, mode, lines = [])

    end

	  # Get list of shapes of given type.
    # @param [Class] shape_info Line object type
	  # @param [SEARCHMODE] mode Search algorithm
    # @param [Array<Wx::SF::Shape>] shapes shape list where all found shapes will be stored
    # @return [Array<Wx::SF::Shape>] shape list
	  # @see SEARCHMODE
    def get_shapes(shape_info, mode = SEARCHMODE::BFS, shapes = [])

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

    end

	  # Get list of all shapes located at given position
    # @param [Wx::Point] pos Logical position
    # @param [Array<Wx::SF::Shape>] shapes shape list where all found shapes will be stored
    # @return [Array<Wx::SF::Shape>] shape list
    # @see Wx::SF::ShapeCanvas::dp2lp
    def get_shapes_at_position(pos, shapes = [])

    end

	  # Get list of shapes located inside given rectangle
	  # @param [Wx::Rect] rct Examined rectangle
    # @param [Array<Wx::SF::Shape>] shapes shape list where all found shapes will be stored
    # @return [Array<Wx::SF::Shape>] shape list
    def get_shapes_inside(rct, shapes = [])

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

    end

    private

    # Update connection shapes after importing/dropping of new shapes
    def update_connections

    end

    # Update grid shapes after importing/dropping of new shapes
    def update_grids

    end

  end

end
