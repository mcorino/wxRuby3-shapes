# Wx::SF::Shape - base shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/serializable'
require 'wx/shapes/shapes/manager_shape'

require 'set'

module Wx::SF

  class ERRCODE < Wx::Enum
    OK = self.new(0)
    NOT_CREATED = self.new(1)
    NOT_ACCEPTED = self.new(2)
    INVALID_INPUT = self.new(3)
  end

  # Base class for all shapes providing fundamental functionality and publishing set
  # of virtual functions which must be defined by the user in derived shapes. This class
  # shouldn't be used as it is.
  #
  # Shape objects derived from this class use hierarchical approach. It means that every
  # shape must have defined parent shape (can be NULL for topmost shapes). An absolute
  # shape position is then calculated as a summation of all relative positions of all parent
  # shapes. Also the size of the parent shape can be limited be a bounding box of all
  # children shapes.
  #
  # This class also declares set of virtual functions used as event handlers for various
  # events (moving, sizing, drawing, mouse events, serialization and deserialization requests, ...)
  # mostly triggered by a parent shape canvas.
  class Shape

    include FIRM::Serializable

    property :id, :active, :visibility, :style,
             :accepted_children, :accepted_connections,
             :accepted_src_neighbours, :accepted_trg_neighbours,
             :hover_colour, :relative_position,
             :h_align, :v_align, :h_border, :v_border,
             :custom_dock_point, :connection_points,
             :user_data
    property child_shapes: :serialize_child_shapes

    class SEARCHMODE < Wx::Enum
      # Depth-First-Search algorithm
      DFS = self.new(0)
        # Breadth-First-Search algorithm
      BFS = self.new(1)
    end

    # Bit flags for Wx::SF::Shape get_complete_bounding_box function
    class BBMODE < Wx::Enum
      SELF = self.new(1)
      CHILDREN = self.new(2)
      CONNECTIONS = self.new(4)
      SHADOW = self.new(8)
      ALL = self.new(15)
    end

    # Search mode flags for get_assigned_connections function
    class CONNECTMODE < Wx::Enum
      # Search for connection starting in examined shape
      STARTING = self.new(0)
      # Search for connection ending in examined shape
      ENDING = self.new(1)
      # Search for both starting and ending connections
      BOTH = self.new(2)
    end

    # Flags for set_v_align function
    class VALIGN < Wx::Enum
      NONE = self.new(0)
      TOP = self.new(1)
      MIDDLE = self.new(2)
      BOTTOM = self.new(3)
      EXPAND = self.new(4)
      LINE_START = self.new(5)
      LINE_END = self.new(6)
    end

    # Flags for set_h_align function
    class HALIGN < Wx::Enum
      NONE = self.new(0)
      LEFT = self.new(1)
      CENTER = self.new(2)
      RIGHT = self.new(3)
      EXPAND = self.new(4)
      LINE_START = self.new(5)
      LINE_END = self.new(6)
    end

    # Basic shape's styles used with set_style function
    class STYLE < Wx::Enum
      # Interactive parent change is allowed
      PARENT_CHANGE = self.new(1)
      # Interactive position change is allowed
      POSITION_CHANGE = self.new(2)
      # Interactive size change is allowed
      SIZE_CHANGE = self.new(4)
      # Shape is highlighted at mouse hovering
      HOVERING = self.new(8)
      # Shape is highlighted at shape dragging
      HIGHLIGHTING = self.new(16)
      # Shape is always inside its parent
      ALWAYS_INSIDE = self.new(32)
      # available
      # XXX = self.new(64)
      # The DEL key is processed by the shape (not by the shape canvas)
      PROCESS_DEL = self.new(128)
      # Show handles if the shape is selected
      SHOW_HANDLES = self.new(256)
      # Show shadow under the shape
      SHOW_SHADOW = self.new(512)
      # Lock children relative position if the parent is resized
      LOCK_CHILDREN = self.new(1024)
      # Emit events (catchable in shape canvas)
      EMIT_EVENTS = self.new(2048)
      # Propagate mouse dragging event to parent shape
      PROPAGATE_DRAGGING = self.new(4096)
      # Propagate selection to parent shape (it means this shape cannot be selected because its focus is redirected to its parent shape)
      PROPAGATE_SELECTION = self.new(8192)
      # Propagate interactive connection request to parent shape (it means this shape cannot be connected interactively because this feature is redirected to its parent shape)
      PROPAGATE_INTERACTIVE_CONNECTION = self.new(16384)
      # Do no resize the shape to fit its children automatically
      NO_FIT_TO_CHILDREN = self.new(32768)
      # Propagate hovering to parent.
      PROPAGATE_HOVERING = self.new(65536)
      # Propagate hovering to parent.
      PROPAGATE_HIGHLIGHTING = self.new(131072)
      # Default shape style
      DEFAULT_SHAPE_STYLE = PARENT_CHANGE | POSITION_CHANGE | SIZE_CHANGE | HOVERING | HIGHLIGHTING | SHOW_HANDLES | ALWAYS_INSIDE
    end

    # Default values
    module DEFAULT
      class << self
        # Default value of Wx::SF::Shape @hoverColor data member
        def hover_colour; Wx::Colour.new(120, 120, 255); end
      end
      # Default value of Wx::SF::Shape @visible data member
      VISIBILITY = true
      # Default value of Wx::SF::Shape @active data member
      ACTIVITY = true
      # Default value of Wx::SF::Shape @relativePosition data member
      POSITION = Wx::RealPoint.new(0, 0)
      # Default value of Wx::SF::Shape @vAlign data member
      VALIGN = VALIGN::NONE
      # Default value of Wx::SF::Shape @hAlign data member
      HALIGN = HALIGN::NONE
      # Default value of Wx::SF::Shape @vBorder data member
      VBORDER = 0.0
      # Default value of Wx::SF::Shape @hBorder data member
      HBORDER = 0.0
      # Default value of Wx::SF::Shape @style data member
      DEFAULT_STYLE = STYLE::DEFAULT_SHAPE_STYLE
      # Default value of Wx::SF::Shape @customDockPoint data member
      DOCK_POINT = -3
    end

    # Provide Shape and derivatives with component set container
    class << self
      def component_shapes
        @component_shapes ||= ::Set.new
      end
    end

    # Declare a component shape property for the shape class.
    # @overload component(*comp_id)
    #   Specifies one or more serialized component properties.
    #   The serialization framework will determine the availability of setter and getter methods
    #   automatically by looking for methods <code>"#{comp_id}=(v)"</code>, <code>"set_#{comp_id}(v)"</code> or <code>"#{comp_id}(v)"</code>
    #   for setters and <code>"#{comp_id}()"</code> or <code>"get_#{comp_id}"</code> for getters.
    #   @param [String,Symbol] comp_id id of component property
    # @overload component(hash)
    #   Specifies one or more serialized component properties with associated setter/getter method ids/procs/lambda-s.
    #   @example
    #     property(
    #       prop_a: ->(obj, *val) {
    #                 obj.my_prop_a_setter(val.first) unless val.empty?
    #                 obj.my_prop_a_getter
    #               },
    #       prop_b: Proc.new { |obj, *val|
    #                 obj.my_prop_b_setter(val.first) unless val.empty?
    #                 obj.my_prop_b_getter
    #               },
    #       prop_c: :serialization_method)
    #   Procs with setter support MUST accept 1 or 2 arguments (1 for getter, 2 for setter).
    #   @note Use `*val` to specify the optional value argument for setter requests instead of `val=nil`
    #         to be able to support setting explicit nil values.
    #   @param [Hash] hash a hash of pairs of property ids and getter/setter procs
    def self.component(*args)
      args.flatten.each do |arg|
        if arg.is_a?(::Hash)
          arg.each_pair do |pn, pp|
            # define serialized property for component (checks for duplicates)
            property({pn => pp}, force: true)
            # get the property definition and register as component
            component_shapes << self.serializer_properties.last
          end
        else
          # define serialized property for component (checks for duplicates)
          property(arg, force: true)
          # get the property definition and register as component
          component_shapes << self.serializer_properties.last
        end
      end
      # check if the current class already has the appropriate support
      unless self.const_defined?(:ComponentSerializerMethods)
        class << self
          def disable_component_serialize(obj)
            component_shapes.each { |pd| pd.get(obj).disable_serialize }
            superclass.disable_component_serialize(obj) if superclass.respond_to?(:disable_component_serialize)
          end

          # override the #new method
          def new(*)
            instance = super
            disable_component_serialize(instance)
            instance
          end
        end
        self.class_eval <<~__CODE
          module ComponentSerializerMethods 
            def from_serialized(hash)
              super(hash)
              #{self.name}.component_shapes.each { |pd| pd.get(self).set_parent_shape(self) }
              self
            end
            protected :from_serialized
          end
          include ComponentSerializerMethods
          __CODE
      end
    end

    # Constructor
    # @param [Wx::RealPoint, Wx::Point] pos Initial relative position
    # @param [Diagram] diagram containing diagram
    def initialize(pos = DEFAULT::POSITION, diagram: nil)
      ::Kernel.raise ArgumentError, "Invalid arguments pos: #{pos}, diagram: #{diagram}" unless
        Wx::RealPoint === pos && (diagram.nil? || Wx::SF::Diagram === diagram)

      @id = FIRM::Serializable::ID.new
      @diagram = diagram
      @parent_shape = nil
      @child_shapes = ShapeList.new
      @components = ::Set.new

      if @diagram
        if @diagram.shape_canvas
          @hover_color = @diagram.shape_canvas.hover_colour
        else
          @hover_color = DEFAULT.hover_colour;
        end
      else
        @hover_color = DEFAULT.hover_colour;
      end

      @selected = false
      @mouse_over = false
      @first_move = false
      @highlight_parent = false
      @user_data = nil

      # archived properties
      @visible = DEFAULT::VISIBILITY
      @active = DEFAULT::ACTIVITY
      @style = DEFAULT::DEFAULT_STYLE
      @v_align = DEFAULT::VALIGN
      @h_align = DEFAULT::HALIGN
      @v_border = DEFAULT::VBORDER
      @h_border = DEFAULT::HBORDER
      @custom_dock_point = DEFAULT::DOCK_POINT

      @relative_position = Wx::RealPoint === pos ? pos.dup : pos.to_real_point

      @handles = []
      @connection_pts = []

      @accepted_children = ::Set.new
      @accepted_connections = ::Set.new
      @accepted_src_neighbours = ::Set.new
      @accepted_trg_neighbours = ::Set.new
    end

    # Get the shape's id
    # @return [FIRM::Serializable::ID]
    def get_id
      @id
    end
    alias :id :get_id

    # Set the shape's id. Deserialization only.
    # @param [FIRM::Serializable::ID] id
    def set_id(id)
      @id = id
    end
    private :set_id

    # Set managing diagram
    # @param [Wx::SF::Diagram] diagram
    def set_diagram(diagram)
      if @diagram != diagram
        @diagram = diagram
        @child_shapes.each { |child| child.set_diagram(diagram) }
      end
      self
    end

    # Get managing diagram
    # @return [Wx::SF::Diagram]
    def get_diagram
      @diagram
    end
    alias :diagram :get_diagram

    # Get the shape canvas of the parent diagram
    # @return [Wx::SF::ShapeCanvas,nil]
    def get_parent_canvas
      @diagram ? @diagram.get_shape_canvas : nil
    end

    # Add a child shape
    # @param [Wx::SF::Shape] shape
    def add_child(shape)
      @child_shapes << shape if shape
    end
    private :add_child

    # Remove a child shape
    # @param [Wx::SF::Shape] shape
    def remove_child(shape)
      @child_shapes.delete(shape) if shape
    end
    private :remove_child

    # Adds child shape is accepted. Removes the child shape as a toplevel diagram shape if appropriate.
    # @param [Wx::SF::Shape] child child shape to add
    # @return [Wx::SF::Shape,nil] added child shape or nil if not accepted
    def add_child_shape(child)
      if is_child_accepted(child.class)
        if child.get_diagram
          child.get_diagram.reparent_shape(child, shape)
        else
          child.set_parent_shape(self)
        end
        child.update
        return child
      end
      nil
    end


    # Find child shape with given ID.
    # @param [FIRM::Serializable::ID] id Shape's ID
    # @param [Boolean] recursive pass true to search recursively, false for non-recursive
    # @return [Wx::SF::Shape, nil] shape if exists, otherwise nil
    def find_child_shape(id, recursive = false)
      @child_shapes.get(id, recursive)
    end

    # Set parent shape object.
    # @param [Wx::SF::Shape] parent
    # @note Note that this does not check this shape against the acceptance list of the parent. Use #add_child_shape if that is required.
    # @note Note that this does not add (if parent == nil) or remove (if parent != nil) the shape from the diagram's
    # toplevel shapes. Use Diagram#reparent_shape when that is needed.
    def set_parent_shape(parent)
      @parent_shape.send(:remove_child, self) if @parent_shape
      parent.send(:add_child, self) if parent
      set_diagram(parent.get_diagram) if parent
      @parent_shape = parent
    end
    alias :parent_shape= :set_parent_shape

    # Get parent shape
    # @return [Wx::SF::Shape,nil] parent shape
    def get_parent_shape
      @parent_shape
    end
    alias :parent_shape :get_parent_shape

    # Get pointer to the topmost parent shape
    # @return [Wx::SF::Shape] topmost parent shape
    def get_grand_parent_shape
      @parent_shape ? @parent_shape.get_grand_parent_shape : self
    end
    alias :grand_parent_shape :get_grand_parent_shape

    # Refresh (redraw) the shape
    # @param [Boolean] delayed If true then the shape canvas will be invalidated rather than refreshed.
    # @see ShapeCanvas#invalidate_rect
    # @see ShapeCanvas#refresh_invalidated_rect
    def refresh(delayed = false)
      refresh_rect(get_bounding_box, delayed)
    end

    # Draw shape. Default implementation tests basic shape visual states
    # (normal/ready, mouse is over the shape, dragged shape can be accepted) and
    # call appropriate virtual functions (DrawNormal, DrawHover, DrawHighlighted)
    # for its visualisation. The function can be overridden if necessary.
    # @param [Wx::DC] dc Reference to a device context where the shape will be drawn to
    # @param [Boolean] children true if the shape's children should be drawn as well
    def draw(dc, children = WITHCHILDREN)
      return unless @diagram && @diagram.shape_canvas
      return unless @visible

      # draw the shape shadow if required
      draw_shadow(dc) if !@selected && has_style?(STYLE::SHOW_SHADOW)

      # first, draw itself
      if @mouse_over && (@highlight_parent || has_style?(STYLE::HOVERING))
        if @highlight_parent
          draw_highlighted(dc)
          @highlight_parent = false
        else
          draw_hover(dc)
        end
      else
        draw_normal(dc)
      end

      draw_selected(dc) if @selected

      # ... then draw connection points ...
      @connection_pts.each { |cpt| cpt.draw(dc) }

      # ... then draw child shapes
      if children
        @child_shapes.each { |child| child.draw(dc) }
      end
    end

    # Test whether the given point is inside the shape. The function
    # can be overridden if necessary.
    # @param [Wx::Point] pos Examined point
    # @return [Boolean] true if the point is inside the shape area, otherwise false
    def contains?(pos)
      # HINT: overload it for custom actions...

      get_bounding_box.contains?(pos)
    end

    # Test whether the shape is completely inside given rectangle. The function
    # can be overridden if necessary.
    # @param [Wx::Rect] rct Examined rectangle
    # @return [Boolean] true if the shape is completely inside given rectangle, otherwise false
    def inside?(rct)
      # HINT: overload it for custom actions...

      rct.contains?(get_bounding_box)
    end

    # Test whether the given rectangle intersects the shape.
    # @param [Wx::Rect] rct Examined rectangle
    # @return [Boolean] true if the examined rectangle intersects the shape, otherwise false
    def intersects?(rct)
      # HINT: overload it for custom actions...

      rct.intersects(get_bounding_box)
    end

    # Get the shape's absolute position in the canvas (calculated as a summation
    # of all relative positions in the shapes' hierarchy. The function can be overridden if necessary.
    # @return [Wx::RealPoint] Shape's position
    def get_absolute_position
      # HINT: overload it for custom actions...
      if @parent_shape
        @relative_position + get_parent_absolute_position
      else
        @relative_position
      end
    end

    # Get intersection point of the shape border and a line leading from
    # 'start' point to 'finish' point.  Default implementation does nothing. The function can be overridden if necessary.
    # @param [Wx::RealPoint] _start Starting point of the virtual intersection line
    # @param [Wx::RealPoint] _finish Ending point of the virtual intersection line
    # @return [Wx::RealPoint] Intersection point
    def get_border_point(_start, _finish)
      # HINT: overload it for custom actions...
      Wx::RealPoint.new
    end

    # Get shape's center. Default implementation does nothing. The function can be overridden if necessary.
    # @return [Wx::RealPoint] Center point
    def get_center
      # HINT: overload it for custom actions...

      bb = get_bounding_box
      Wx::RealPoint.new(bb.left + bb.width/2, bb.top + bb.height/2)
    end

    # Function called by the framework responsible for creation of shape handles
    # at the creation time. Default implementation does nothing. The function can be overridden if necessary.
    def create_handles
      # HINT: overload it for custom actions...
    end

    # Show/hide shape handles. Hidden handles are inactive.
    # @param [Boolean] show true for showing, false for hiding
    def show_handles(show)
      @handles.each { |h| h.show(show) }
    end

    # Set shape's style.
    #
    # Default value is STYLE::PARENT_CHANGE | STYLE::POSITION_CHANGE | STYLE::SIZE_CHANGE | STYLE::HOVERING | STYLE::HIGHLIGHTING | STYLE::SHOW_HANDLES | STYLE::ALWAYS_INSIDE
    # @param [Integer] style Combination of the shape's styles
    # @see STYLE
    def set_style(style)
      @style = style
    end
    alias :style= :set_style

    # Get current shape style.
    # @return [Integer] shape style
    def get_style
      @style
    end
    alias :style :get_style

    def add_style(style)
      @style |= style
    end
    def remove_style(style)
      @style &= ~style
    end
    def contains_style(style)
      (@style & style) != 0
    end
    alias :contains_style? :contains_style
    alias :has_style? :contains_style

    # Find out whether this shape has some children.
    # @return [Boolean] true if the parent shape has children, otherwise false
    def has_children
      !@child_shapes.empty?
    end
    alias :has_children? :has_children

    # Get children of given type.
    # @param [Class,nil] type Child shape type (if nil then all children are returned)
    # @param [Array<Wx::SF::Shape>] list list where all found child shapes will be appended
    # @return [Array<Wx::SF::Shape>] list with appended child shapes
    def get_children(type, list)
      @child_shapes.each_with_object(list) { |child, lst| lst << child if type.nil? || type === child }
    end

    # Get all children of given type recursively (i.e. children of children of .... ).
    # @param [Class,nil] type Child shape type (if nil then all children are returned)
    # @param [Array<Wx::SF::Shape>] list list where all found child shapes will be appended
    # @param [SEARCHMODE] mode Search mode. User can choose Depth-First-Search or Breadth-First-Search algorithm (BFS is default)
    # @see SEARCHMODE
    def get_children_recursively(type, mode = SEARCHMODE::BFS, list = [])
      @child_shapes.each do |child|
        list << child if type.nil? || type === child
        child.get_children_recursively(type, mode, list) if mode == SEARCHMODE::DFS
      end
      if mode == SEARCHMODE::BFS
        @child_shapes.each { |child| child.get_children_recursively(type, mode, list) }
      end
      list
    end

    # Get child shapes associated with this (parent) shape.
    # @param [Class,nil] type Type of searched child shapes (nil for any type)
    # @param [Boolean] recursive Set this flag true if also children of children of ... should be found (also RECURSIVE or NORECURSIVE constants can be used).
    # @param [SEARCHMODE] mode Search mode (has sense only for recursive search)
    # @param [Array<Wx::SF::Shape>] list of child shapes to fill
    # @return [Array<Wx::SF::Shape>] list of child shapes filled
    def get_child_shapes(type, recursive = NORECURSIVE, mode = SEARCHMODE::BFS, list = [])
      if recursive
        get_children_recursively(type, mode, list)
      else
        get_children(type, list)
      end
    end

	  # Get neighbour shapes connected to this shape.
	  # @param [Class,nil] shape_info Line object type
	  # @param [CONNECTMODE] condir Connection direction
	  # @param [Boolean] direct Set this flag to true if only closest shapes should be found, otherwise also shapes connected by forked lines will be found (also constants DIRECT and INDIRECT can be used)
    # @param [Array<Wx::SF::Shape>] neighbours List of neighbour shapes
    # @return [Array<Wx::SF::Shape>] list of neighbour shapes filled
	  # @see CONNECTMODE
    def get_neighbours(shape_info, condir, direct = DIRECT, neighbours = [])
      unless Wx::SF::LineShape === self
        _get_neighbours(shape_info, condir, direct, neighbours)
        # delete starting object if necessary (can be added in a case of complex connection network)
        neighbours.delete(self)
      end
      neighbours
    end

	  # Get list of connections assigned to this shape.
	  # @note For proper functionality the shape must be managed by a diagram manager.
	  # @param [Class] shape_info Line object type
	  # @param [CONNECTMODE] mode Search mode
	  # @param [Array<Wx::SF::Shape>] lines shape list where all found connections will be stored
    # @return [Array<Wx::SF::Shape>] list of connection shapes filled
	  # @see CONNECTMODE
    def get_assigned_connections(shape_info, mode, lines = [])
      @diagram.get_assigned_connections(self, shape_info, mode, lines) if @diagram
      lines
    end

    # Get shape's bounding box. The function can be overridden if necessary.
    # @return [Wx::Rect] Bounding rectangle
    def get_bounding_box
      # HINT: overload it for custom actions...

      Wx::Rect.new
    end

	  # Get shape's bounding box which includes also associated child shapes and connections.
	  # @param [Wx::Rect] rct bounding rectangle
	  # @param [BBMODE] mask Bit mask of object types which should be included into calculation
    # @return [Wx::Rect] returned bounding box
	  # @see BBMODE
    def get_complete_bounding_box(rct, mask = BBMODE::ALL)
      _get_complete_bounding_box(rct, mask)
    end

    # Scale the shape size in both directions. The function can be overridden if necessary
    # (new implementation should call default one or scale shape's children manually if necessary).
    # @overload scale(x,y, children: WITHCHILDREN)
    #   @param [Float] x Horizontal scale factor
    #   @param [Float] y Vertical scale factor
    #   @param [Boolean] children true if the shape's children should be scaled as well, otherwise the shape will be updated after scaling via #update function.
    # @overload scale(scale, children: WITHCHILDREN)
    #   @param [Wx::RealPoint] scale scale factors
    #   @param [Boolean] children true if the shape's children should be scaled as well, otherwise the shape will be updated after scaling via #update function.
    def scale(*args, children: WITHCHILDREN)
      # HINT: overload it for custom actions...

      x, y = (args.size == 1 ? args.first : args)
      scale_children(x, y) if children

      @diagram.set_modified(true) if @diagram
      # self.update
    end

    # Scale shape's children
    # @param [Float] x Horizontal scale factor
    # @param [Float] y Vertical scale factor
    # @see Scale
    def scale_children(x, y)
      lst_children = get_child_shapes(ANY, RECURSIVE)

      lst_children.each do |shape|
        if shape.has_style?(STYLE::SIZE_CHANGE) && shape.is_a?(Wx::SF::TextShape)
          shape.scale(x, y, children: WITHOUTCHILDREN)
        end

        if shape.has_style?(STYLE::POSITION_CHANGE) && (shape.get_v_align == VALIGN::NONE || shape.get_h_align == HALIGN::NONE)
          shape.set_relative_position(shape.get_relative_position.x*x, shape.get_relative_position.y*y)
        end

        # re-align shapes which have set any alignment mode
        shape.do_alignment
      end
    end

    # Move the shape to the given absolute position. The function can be overridden if necessary.
    # @overload move_to(x,y)
	  #   @param [Float] x X coordinate
	  #   @param [Float] y Y coordinate
    # @overload move_to(pos)
    #   @param [Wx::RealPoint] pos New absolute position
    def move_to(*args)
      # HINT: overload it for custom actions...

      pos = (args.size == 1 ? args.first.to_real_point : Wx::RealPoint.new(*args))
      @relative_position = pos - get_parent_absolute_position

      @diagram.set_modified(true) if @diagram
    end

    # Move the shape by the given offset. The function can be overridden if necessary.
    # @overload move_by(x,y)
	  #   @param [Float] x X offset
	  #   @param [Float] y Y offset
    # @overload move_by(delta)
    #   @param [Wx::RealPoint] delta Offset
    def move_by(*args)
      # HINT: overload it for custom actions...

      x, y = (args.size == 1 ? args.first : args)
      @relative_position.x += x
      @relative_position.y += y

      @diagram.set_modified(true) if @diagram
    end

    # Returns true if this shape manages (size/position/alignment) of it's child shapes.
    # Returns false by default.
    # @return [Boolean]
    def is_manager
      false
    end
    alias :manager? :is_manager

    # Returns true if this shape is managed (size/position/alignment) by it's parent shape.
    # @return [Boolean]
    def is_managed
      !!@parent_shape&.is_manager
    end
    alias :managed? :is_managed


    # Update the shape's position in order to its alignment
    def do_alignment
      # align to parent unless parent is manager
      unless @parent_shape.nil? || managed?
        if @parent_shape.is_a?(Wx::SF::LineShape)
          line_pos = get_parent_absolute_position
          parent_bb = Wx::Rect.new(line_pos.x.to_i, line_pos.y.to_i, 1, 1)
        else
          parent_bb = @parent_shape.get_bounding_box
        end

        shape_bb = get_bounding_box

        # do vertical alignment
        case @v_align
        when VALIGN::TOP
          @relative_position.y = @v_border

        when VALIGN::MIDDLE
          @relative_position.y = parent_bb.height/2 - shape_bb.height/2

        when VALIGN::BOTTOM
          @relative_position.y = parent_bb.height - shape_bb.height - @v_border

        when VALIGN::EXPAND
          if has_style?(STYLE::SIZE_CHANGE)
            @relative_position.y = @v_border
            scale(1.0, ((parent_bb.height - 2*@v_border)/shape_bb.height).to_f)
          end

        when VALIGN::LINE_START
          if @parent_shape.is_a?(Wx::SF::LineShape)
            line_start, line_end = @parent_shape.get_line_segment(0)

            if line_end.y >= line_start.y
              @relative_position.y = line_start.y - line_pos.y + @v_border
            else
              @relative_position.y = line_start.y - line_pos.y - shape_bb.height - @v_border
            end
          end

        when VALIGN::LINE_END
          if @parent_shape.is_a?(Wx::SF::LineShape)
            line_start, line_end = @parent_shape.get_line_segment(parent.get_control_points.get_count)

            if line_end.y >= line_start.y
              @relative_position.y = line_end.y - line_pos.y - shape_bb.height - @v_border
            else
              @relative_position.y = line_end.y - line_pos.y + @v_border
            end
          end
        end

        # do horizontal alignment
        case @h_align
        when HALIGN::LEFT
          @relative_position.x = @h_border

        when HALIGN::CENTER
          @relative_position.x = parent_bb.width/2 - shape_bb.width/2

        when HALIGN::RIGHT
          @relative_position.x = parent_bb.width - shape_bb.width - @h_border

        when HALIGN::EXPAND
          if has_style?(STYLE::SIZE_CHANGE)
            @relative_position.x = @h_border
            scale(((parent_bb.width - 2*@h_border)/shape_bb.width).to_f, 1.0)
          end

        when HALIGN::LINE_START
          if @parent_shape.is_a?(Wx::SF::LineShape)
            line_start, line_end = @parent_shape.get_line_segment(0)

            if line_end.x >= line_start.x

              @relative_position.x = line_start.x - line_pos.x + @h_border
            else
              @relative_position.x = line_start.x - line_pos.x - shape_bb.width - @h_border
            end
          end

        when HALIGN::LINE_END
          if @parent_shape.is_a?(Wx::SF::LineShape)
            line_start, line_end = @parent_shape.get_line_segment(@parent_shape.get_control_points.get_count)

            if line_end.x >= line_start.x
              @relative_position.x = line_end.x - line_pos.x - shape_bb.width - @h_border
            else
              @relative_position.x = line_end.x - line_pos.x + @h_border
            end
          end
        end
      end
    end

    # Update shape (align all child shapes and resize it to fit them)
    def update
      # do self-alignment
      do_alignment

      # do alignment of shape's children (if required)
      @child_shapes.each { |child| child.do_alignment }

      # fit the shape to its children
      fit_to_children unless has_style?(STYLE::NO_FIT_TO_CHILDREN)

      # do it recursively on all parent shapes
      if (parent = get_parent_shape)
        parent.update
      end
    end

    # Resize the shape to bound all child shapes. The function can be overridden if necessary.
    def fit_to_children
      # HINT: overload it for custom actions...
    end

    # Function returns true if the shape is selected, otherwise returns false
    def selected?
      @selected
    end

    # Set the shape as a selected/deselected one
    # @param [Boolean] state Selection state (true is selected, false is deselected)
    def select(state)
      @selected = state
      show_handles(state && (@style & STYLE::SHOW_HANDLES) != 0)
    end

    # Set shape's relative position. Absolute shape's position is then calculated
    # as a summation of the relative positions of this shape and all parent shapes in the shape's
    # hierarchy.
    # @overload set_relative_position(pos)
    #   @param [Wx::RealPoint] pos New relative position
    # @overload set_relative_position(x,y)
    #   @param [Float] x Horizontal coordinate of new relative position
    #   @param [Float] y Vertical coordinate of new relative position
    # @see #move_to
    def set_relative_position(*arg)
      x, y = (arg.size == 1 ? arg.first.to_real_point : arg)
      @relative_position.x = x
      @relative_position.y = y
    end

    # Get shape's relative position.
    # @return [Wx::RealPoint] Current relative position
    # @see #get_absolute_position
    def get_relative_position
      @relative_position
    end

	  # Set vertical alignment of this shape inside its parent
	  # @param [VALIGN] val Alignment type
	  # @see VALIGN
    def set_v_align(val)
      @v_align = val
    end
    alias :v_align= :set_v_align

	  # Get vertical alignment of this shape inside its parent
	  # @return [VALIGN] Alignment type
	  # @see VALIGN
    def get_v_align
      @v_align
    end
    alias :v_align :get_v_align

	  # Set horizontal alignment of this shape inside its parent
	  # @param [HALIGN] val Horizontal type
	  # @see HALIGN
    def set_h_align(val)
      @h_align = val
    end
    alias :h_align= :set_h_align

	  # Get horizontal alignment of this shape inside its parent
	  # @return [HALIGN] Alignment type
	  # @see HALIGN
    def get_h_align
      @h_align
    end
    alias :h_align :get_h_align

	  # Set vertical border between this shape and its parent (if vertical
	  # alignment is set).
	  # @param [Float] border Vertical border
	  # @see #set_v_align
    def set_v_border(border)
      @v_border = border
    end
    alias :v_border= :set_v_border

	  # Get vertical border between this shape and its parent (if vertical
	  # alignment is set).
	  # @return [Float] Vertical border
	  # @see #set_v_align
    def get_v_border
      @v_border
    end
    alias :v_border :get_v_border

	  # Set horizontal border between this shape and its parent (if horizontal
	  # alignment is set).
	  # @param [Float] border Horizontal border
	  # @see #set_h_align
    def set_h_border(border)
      @h_border = border
    end
    alias :h_border= :set_h_border

	  # Get horizontal border between this shape and its parent (if horizontal
	  # alignment is set).
	  # @return [Float] Vertical border
	  # @see #set_h_align
    def get_h_border
      @h_border
    end
    alias :h_border :get_h_border

	  # Set custom dock point used if the shape is child shape of a line shape.
	  # @param [Integer] dp Custom dock point
    def set_custom_dock_point(dp)
      @custom_dock_point = dp
    end
    alias :custom_dock_point= :set_custom_dock_point

	  # Get custom dock point used if the shape is child shape of a line shape.
	  # @return [Integer] Custom dock point
    def get_custom_dock_point
      @custom_dock_point
    end
    alias :custom_dock_point :get_custom_dock_point

	  # Determine whether this shape is ancestor of given child shape.
	  # @param [Wx::SF::Shape] child child shape.
	  # @return true if this shape is parent of given child shape, otherwise false
    def ancestor?(child)
      @child_shapes.include?(child) || @child_shapes.any? { |c| c.ancestor?(child) }
    end

	  # Determine whether this shape is descendant of given parent shape.
	  # @param [Wx::SF::Shape] parent parent shape
	  # @return true if this shape is a child of given parent shape, otherwise false
    def descendant?(parent)
      parent && parent.ancestor?(self)
    end

    # Associate user data with the shape.
    # If the data object is properly set then its marked properties will be serialized
    # together with the parent shape. This means the user data must either be a serializable
    # core type or a FIRM::Serializable.
    # @param [Object] data user data
    def set_user_data(data)
      @user_data = data
    end
    alias :user_data= :set_user_data

    # Get associated user data.
    # @return [Object,nil] user data
    def get_user_data
      @user_data
    end
    alias :user_data :get_user_data

	  # Get shape's diagram canvas
	  # @return [Wx::SF::ShapeCanvas,nil] shape canvas if assigned via diagram, otherwise nil
	  # @see Wx::SF::Diagram
    def get_shape_canvas
      return nil unless @diagram

      @diagram.shape_canvas
    end
    alias :shape_canvas :get_shape_canvas

	  # Get the shape's visibility status
    # @return [Boolean] true if the shape is visible, otherwise false
    def visible?
      @visible
    end
   alias :visibility :visible?

	  # Show/hide shape
    # @param [Boolean] show Set the parameter to true if the shape should be visible, otherwise use false
    def show(show)
      @visible = show
    end
    alias :set_visibility :show

	  # Set shape's hover color
	  # @param [Wx::Colour,String,Symbol] col Hover color
    def set_hover_colour(col)
      @hover_color = Wx::Colour === col ? col : Wx::Colour.new(col)
    end
    alias :hover_colour= :set_hover_colour

	  # Get shape's hover color
    # @return [Wx::Colour] Current hover color
    def get_hover_colour
      @hover_color
    end
    alias :hover_colour :get_hover_colour

	  # Function returns value of a shape's activation flag.
	  # Non-active shapes are visible, but don't receive (process) any events.
    # @return [Boolean] true if the shape is active, otherwise false
    def active?
      @active
    end
    alias :active :active?

	  # Shape's activation/deactivation
	  # Deactivated shapes are visible, but don't receive (process) any events.
    # @param [Boolean] active true for activation, false for deactivation
    # @see #show
    def activate(active)
      @active = active
    end
    alias :set_active :activate

    # Tells whether the given shape type is accepted by this shape (it means
    # whether this shape can be its parent).
    #
    # The function is typically used by the framework for determination whether a dropped
    # shape can be assigned to an underlying shape as its child.
    # @param [Class] type Class of examined shape object
    # @return [Boolean] true if the shape type is accepted, otherwise false.
    def is_child_accepted(type)
      @accepted_children.include?(type) || @accepted_children.include?(ACCEPT_ALL)
    end
    alias :child_accepted? :is_child_accepted

    # Returns true if *all* currently dragged shapes can be accepted
    # as children of this shape.
    # @return [Boolean]
    # @see #is_shape_accepted
    def accept_currently_dragged_shapes
      return false unless get_shape_canvas

      unless is_child_accepted(ACCEPT_ALL)
        lst_selection = get_shape_canvas.get_selected_shapes

        return false if lst_selection.any? { |shape| !@accepted_children.include?(shape.class.name) }
      end
      true
    end

    # Add given shape type to an acceptance list. The acceptance list contains class
    # names of the shapes which can be accepted as children of this shape.
    # Note: Constant value {Wx::SF::ACCEPT_ALL} behaves like any class.
    # @param [Class] type Class of accepted shape object
    # @see #is_child_accepted
    def accept_child(type)
      ::Kernel.raise ArgumentError, 'Class or ACCEPT_ALL expected' unless type.is_a?(::Class)
      @accepted_children << type
    end

    # Get shape types acceptance list.
	  # @return [Set<String>] String set with class names of accepted shape types.
	  # @see #is_child_accepted
    def get_accepted_children
      @accepted_children
    end
    alias :accepted_children :get_accepted_children

    # Tells whether the shape does not accept ANY children
    # @return [Boolean] true if no children accepted, false otherwise
    def does_not_accept_children?
      @accepted_children.empty?
    end
    alias :no_children_accepted? :does_not_accept_children?
    alias :accepts_no_children? :does_not_accept_children?

    # Tells whether the given connection type is accepted by this shape (it means
    # whether this shape can be connected to another one by a connection of given type).
    #
    # The function is typically used by the framework during interactive connection creation.
    # @param [Class] type Class of examined connection object
    # @return true if the connection type is accepted, otherwise false.
    def is_connection_accepted(type)
      @accepted_connections.include?(type) || @accepted_connections.include?(ACCEPT_ALL)
    end
    alias :connection_accepted? :is_connection_accepted

    # Add given connection type to an acceptance list. The acceptance list contains class
    # names of the connection which can be accepted by this shape.
    # Note: Constant value {Wx::SF::ACCEPT_ALL} behaves like any class.
    # @param [Class] type Class of accepted connection object
    # @see #is_connection_accepted
    def accept_connection(type)
      ::Kernel.raise ArgumentError, 'Class or ACCEPT_ALL expected' unless type.is_a?(::Class)
      @accepted_connections << type
    end

    # Get connection types acceptance list.
	  # @return [Set<String>] String set with class names of accepted connection types.
	  # @see #is_connection_accepted
    def get_accepted_connections
      @accepted_connections
    end
    alias :accepted_connections :get_accepted_connections

    # Tells whether the given shape type is accepted by this shape as its source neighbour(it means
    # whether this shape can be connected from another one of given type).
    #
    # The function is typically used by the framework during interactive connection creation.
    # @param [Class] type Class of examined connection object
    # @return true if the shape type is accepted, otherwise false.
    def is_src_neighbour_accepted(type)
      @accepted_src_neighbours.include?(type) || @accepted_src_neighbours.include?(ACCEPT_ALL)
    end
    alias :src_neighbour_accepted? :is_src_neighbour_accepted

    # Add given shape type to an source neighbours' acceptance list. The acceptance list contains class
    # names of the shape types which can be accepted by this shape as its source neighbour.
    # Note: Constant value {Wx::SF::ACCEPT_ALL} behaves like any class.
    # @param [Class] type Class of accepted connection object
    # @see #is_src_neighbour_accepted
    def accept_src_neighbour(type)
      ::Kernel.raise ArgumentError, 'Class or ACCEPT_ALL expected' unless type.is_a?(::Class)
      @accepted_src_neighbours << type
    end

    # Get source neighbour types acceptance list.
	  # @return [Set<String>] String set with class names of accepted source neighbours types.
	  # @see #is_src_neighbour_accepted
    def get_accepted_src_neighbours
      @accepted_src_neighbours
    end
    alias :accepted_src_neighbours :get_accepted_src_neighbours

    # Tells whether the given shape type is accepted by this shape as its target neighbour(it means
    # whether this shape can be connected to another one of given type).
    #
    # The function is typically used by the framework during interactive connection creation.
    # @param [Class] type Class of examined connection object
    # @return [Boolean] true if the shape type is accepted, otherwise false.
    def is_trg_neighbour_accepted(type)
      @accepted_trg_neighbours.include?(type) || @accepted_trg_neighbours.include?(ACCEPT_ALL)
    end
    alias :trg_neighbour_accepted? :is_trg_neighbour_accepted

    # Add given shape type to an target neighbours' acceptance list. The acceptance list contains class
    # names of the shape types which can be accepted by this shape as its target neighbour.
    # Note: Constant value {Wx::SF::ACCEPT_ALL} behaves like any class.
    # @param [Class] type Class of accepted connection object
    # @see #is_trg_neighbour_accepted
    def accept_trg_neighbour(type)
      ::Kernel.raise ArgumentError, 'Class or ACCEPT_ALL expected' unless type.is_a?(::Class)
      @accepted_trg_neighbours << type
    end

    # Get target neighbour types acceptance list.
	  # @return [Set<String>] String set with class names of accepted target neighbours types.
	  # @see #is_trg_neighbour_accepted
    def get_accepted_trg_neighbours
      @accepted_trg_neighbours
    end
    alias :accepted_trg_neighbours :get_accepted_trg_neighbours

    # Clear shape object acceptance list
	  # @see #accept_child
    def clear_accepted_childs
      @accepted_children.clear
    end

    # Clear connection object acceptance list
	  # @see #accept_connection
    def clear_accepted_connections
      @accepted_connections.clear
    end

    # Clear source neighbour objects acceptance list
	  # @see #accept_src_neighbour
    def clear_accepted_src_neighbours
      @accepted_src_neighbours.clear
    end

    # Clear target neighbour objects acceptance list
	  # @see #accept_trg_neighbour
    def clear_accepted_trg_neighbours
      @accepted_trg_neighbours.clear
    end

    # Get list of currently assigned shape handles.
    # @return [Array<Wx::SF::Shape::Handle>] handle list
    def get_handles
      @handles
    end
    alias :handles :get_handles

    # Get shape handle.
	  # @param [Wx::SF::Shape::Handle::TYPE] type Handle type
	  # @param [Integer] id Handle ID (useful only for line control points)
	  # @return [Wx::SF::Shape::Handle,nil] shape handle object if exist
	  # @see Wx::SF::Shape::Handle
    def get_handle(type, id = -1)
      @handles.find { |h| h.type == type && (id == -1 || h.id == id) }
    end
    alias :handle :get_handle

    # Add new handle to the shape.
	  #
	  # The function creates new instance of shape handle (if it doesn't exist yet)
	  # and inserts it into handle list.
    # @param [Wx::SF::Shape::Handle::TYPE] type Handle type
    # @param [Integer] id Handle ID (useful only for line control points)
    # @see Wx::SF::Shape::Handle
    def add_handle(type, id = -1)
      unless get_handle(type, id)
        @handles << Handle.new(self, type, id)
      end
    end

    # Remove given shape handle (if exists).
    # @param [Wx::SF::Shape::Handle::TYPE] type Handle type
    # @param [Integer] id Handle ID (useful only for line control points)
    # @see Wx::SF::Shape::Handle
    def remove_handle(type, id = -1)
      @handles.delete_if { |h| h.type == type && (id == -1 || h.id == id) }
    end

    # Get reference to connection points list.
	  # @return [Array<Wx::SF::ConnectionPoint>] connection points list
    def get_connection_points
      @connection_pts
    end
    alias :connection_points :get_connection_points

    # Get connection point of given type assigned to the shape.
	  # @param [Wx::SF::ConnectionPoint::CPTYPE] type Connection point type
	  # @param [Integer] id Optional connection point ID
	  # @return [Wx::SF::ConnectionPoint,nil] connection point if exists, otherwise nil
	  # @see Wx::SF::ConnectionPoint::CPTYPE
    def get_connection_point(type, id = -1)
      @connection_pts.find { |cp| cp.type == type && cp.id == id }
    end
    alias :connection_point :get_connection_point

    # Get connection point closest to the given position.
	 # @param [Wx::RealPoint] pos Position
	 # @return [Wx::SF::ConnectionPoint,nil] closest connection point if exists, otherwise nil
    def get_nearest_connection_point(pos)
      pos = pos.to_real_point
      min_dist = Float::MAX
      @connection_pts.inject(nil) do |nearest, cp|
        if (curr_dist = pos.distance_to(cp.get_connection_point)) < min_dist
          min_dist = curr_dist
          nearest = cp
        end
        nearest
      end
    end
    alias :nearest_connection_point :get_nearest_connection_point

    # Assign connection point of given type to the shape.
    # @overload add_connection_point(type, persistent: true)
    #   @param [Wx::SF::ConnectionPoint::CPTYPE] type Connection point type
	  #   @param [Boolean] persistent true if the connection point should be serialized
	  #   @return [Wx::SF::ConnectionPoint, nil] new connection point if succeeded, otherwise nil
    # @overload add_connection_point(relpos, id=-1, persistent: true)
    #   @param [Wx::RealPoint] relpos Relative position in percentages
    #   @param [Integer] id connection point ID
    #   @param [Boolean] persistent true if the connection point should be serialized
    #   @return [Wx::SF::ConnectionPoint, nil] new connection point if succeeded, otherwise nil
    # @overload add_connection_point(cp, persistent: true)
    #   @param [Wx::SF::ConnectionPoint] cp connection point (shape will take the ownership)
    #   @param [Boolean] persistent true if the connection point should be serialized
    #   @return [Wx::SF::ConnectionPoint, nil] added connection point if succeeded, otherwise nil
	  # @see Wx::SF::ConnectionPoint::CPTYPE
    def add_connection_point(arg, *rest, persistent: true)
      cp = nil
      case arg
      when ConnectionPoint::CPTYPE
        unless get_connection_point(arg)
          cp = ConnectionPoint.new(self, arg)
          cp.disable_serialize unless persistent
        end
      when Wx::RealPoint, ::Array
        cp = ConnectionPoint.new(self, arg.to_real_point, *rest)
        cp.disable_serialize unless persistent
      when ConnectionPoint
        cp = arg
        cp.disable_serialize unless persistent
      else
        ::Kernel.raise ArgumentError, "Invalid arguments: arg: #{arg}, rest: #{rest}"
      end
      @connection_pts << cp if cp
      cp
    end

    # Remove connection point of given type from the shape (if present).
    # @param [Wx::SF::ConnectionPoint::CPTYPE] type Connection point type
	  # @see Wx::SF::ConnectionPoint::CPTYPE
    def remove_connection_point(type)
      @connection_pts.delete_if { |cp| cp.type == type }
    end

    # Event handler called when the shape is clicked by
	  # the left mouse button. The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_LEFT_DOWN event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_left_click(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_LEFT_DOWN, self.id)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when the shape is clicked by
	  # the right mouse button. The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_RIGHT_DOWN event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_right_click(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_RIGHT_DOWN, self.id)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when the shape is double-clicked by
	  # the left mouse button. The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_LEFT_DCLICK event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_left_double_click(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_LEFT_DCLICK, self.id)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when the shape is double-clicked by
	  # the right mouse button. The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_RIGHT_DCLICK event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_right_double_click(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_RIGHT_DCLICK, self.id)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end

    # Event handler called at the beginning of the shape dragging process.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_DRAG_BEGIN event.
    # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_begin_drag(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_DRAG_BEGIN, self.id)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called during the shape dragging process.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_DRAG event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_dragging(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_DRAG, self.id)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called at the end of the shape dragging process.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_DRAG_END event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_end_drag(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_DRAG_END, self.id)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end

    # Event handler called when the user started to drag the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_HANDLE_BEGIN event.
	  # @param [Wx::SF::Shape::Handle] handle dragged handle
    def on_begin_handle(handle)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeHandleEvent.new(Wx::SF::EVT_SF_SHAPE_HANDLE_BEGIN, self.id)
        evt.set_shape(self)
        evt.set_handle(handle)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called during dragging of the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_HANDLE event.
    # @param [Wx::SF::Shape::Handle] handle dragged handle
    def on_handle(handle)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeHandleEvent.new(Wx::SF::EVT_SF_SHAPE_HANDLE, self.id)
        evt.set_shape(self)
        evt.set_handle(handle)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when the user finished dragging of the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_HANDLE_END event.
    # @param [Wx::SF::Shape::Handle] handle dragged handle
    def on_end_handle(handle)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeHandleEvent.new(Wx::SF::EVT_SF_SHAPE_HANDLE_END, self.id)
        evt.set_shape(self)
        evt.set_handle(handle)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when a mouse pointer enters the shape area.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_MOUSE_ENTER event.
	  # @param [Wx::Point] pos Current mouse position
    def on_mouse_enter(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_MOUSE_ENTER, self.id)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when a mouse pointer moves above the shape area.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_MOUSE_OVER event.
	  # @param [Wx::Point] pos Current mouse position
    def on_mouse_over(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_MOUSE_OVER, self.id)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when a mouse pointer leaves the shape area.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_MOUSE_LEAVE event.
	  # @param [Wx::Point] pos Current mouse position
    def on_mouse_leave(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_MOUSE_LEAVE, self.id)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end

    # Event handler called when any key is pressed (in the shape canvas).
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_KEYDOWN event.
	  # @param [Integer] key The key code
	  # @return The function must return true if the default event routine should be called
	  #         as well, otherwise false
	  # @see Wx::SF::Shape::_on_key
    def on_key(key)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeKeyEvent.new(Wx::SF::EVT_SF_SHAPE_KEYDOWN, self.id)
        evt.set_shape(self)
        evt.set_key_code(key)
        get_shape_canvas.get_event_handler.process_event(evt)
      end

      true
    end

    # Event handler called when any shape is dropped above this shape (and the dropped
	  # shape is accepted as a child of this shape). The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::SF::EVT_SF_SHAPE_CHILD_DROP event.
	  # @param [Wx::RealPoint] _pos Relative position of dropped shape
	  # @param [Wx::SF::Shape] child dropped shape
    def on_child_dropped(_pos, child)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeChildDropEvent.new(Wx::SF::EVT_SF_SHAPE_CHILD_DROP, self.id)
        evt.set_shape(self)
        evt.set_child_shape(child)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end

    def to_s
      "#<#{self.class}:#{id.to_i}#{@parent_shape ? " parent=#{@parent_shape.id.to_i}" : ''}>"
    end

    def inspect
      to_s
    end

    protected

    # called after the shape has been newly imported/pasted/dropped
    # allows for checking stale links
    # by default does nothing
    def on_import
      # nothing
    end

	  # Draw the shape in the normal way. The function can be overridden if necessary.
	  # @param [Wx::DC] _dc Reference to device context where the shape will be drawn to
    def draw_normal(_dc)
      # HINT: overload it for custom actions...
    end

	  # Draw the shape in the selected way. The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_selected(dc)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::SHOW_HANDLES)
        @handles.each { |h| h.send(:draw, dc) }
      end
    end

	  # Draw the shape in the hover mode (the mouse cursor is above the shape).
	  # The function can be overridden if necessary.
	  # @param [Wx::DC] _dc Reference to device context where the shape will be drawn to
    def draw_hover(_dc)
      # HINT: overload it for custom actions...
    end

	  # Draw the shape in the highlighted mode (another shape is dragged over this
	  # shape and this shape will accept the dragged one if it will be dropped on it).
	  # The function can be overridden if necessary.
	  # @param [Wx::DC] _dc Reference to device context where the shape will be drawn to
    def draw_highlighted(_dc)
      # HINT: overload it for custom actions...
    end

	  # Draw shadow under the shape. The function can be overridden if necessary.
	  # @param [Wx::DC] _dc Reference to device context where the shadow will be drawn to
    def draw_shadow(_dc)
      # HINT: overload it for custom actions...
    end

    # Repaint the shape
    # @param [Wx::Rect] rct Canvas portion that should be updated
	  # @param [Boolean] delayed If true then the shape canvas will be rather invalidated than refreshed.
	  # @see Wx::SF::ShapeCanvas#invalidate_rect
    # @see Wx::SF::ShapeCanvas#refresh_invalidated_rect
    def refresh_rect(rct, delayed = false)
      if get_shape_canvas
        if delayed
          get_shape_canvas.invalidate_rect(rct)
        else
          get_shape_canvas.refresh_canvas(false, rct)
        end
      end
    end

	  # Get absolute position of the shape parent.
	  # @return [Wx::RealPoint] Absolute position of the shape parent if exists, otherwise 0,0
    def get_parent_absolute_position
      if @parent_shape
        if @parent_shape.is_a?(Wx::SF::LineShape) && @custom_dock_point != DEFAULT::DOCK_POINT
          return @parent_shape.get_dock_point_position(@custom_dock_point)
        else
          return @parent_shape.get_absolute_position
        end
      end

      Wx::RealPoint.new(0, 0)
    end

    private

    # Auxiliary function called by GetNeighbours function.
	  # @param [Class,nil] shape_info Line object type
	  # @param [CONNECTMODE] condir Connection direction
	  # @param [Boolean] direct Set this flag to TRUE if only closest shapes should be found,
	  #     otherwise also shapes connected by forked lines will be found (also
	  #     constants DIRECT and INDIRECT can be used)
    # @param [Array<Wx::SF::Shape] neighbours List to add neighbour shapes to
    # @param [Set<Wx::SF::Shape] processed set to keep track of processed shapes
    # @return [Array<Wx::SF::Shape] List of neighbour shapes
	  # @see #get_neighbours
    def _get_neighbours(shape_info, condir, direct, neighbours, processed = ::Set.new)
      if @diagram
        return if processed.include?(self)

        opposite = nil

        lst_connections = get_assigned_connections(shape_info, condir)

        # find opposite shapes in direct branches
        lst_connections.each do |line|
          case condir
          when CONNECTMODE::STARTING
            opposite = line.get_trg_shape

          when CONNECTMODE::ENDING
            opposite = line.get_src_shape

          when CONNECTMODE::BOTH
            if self == line.get_src_shape
              opposite = line.get_trg_shape
            else
              opposite = line.get_src_shape
            end
          end

          # add opposite shape to the list (if applicable)
          neighbours << opposite if opposite && !opposite.is_a?(Wx::SF::LineShape) && !neighbours.include?(opposite)

          # find next shapes
          if !direct && opposite
            # in the case of indirect branches we must differentiate between connections
            # and ordinary shapes
            processed << self

            if opposite.is_a?(Wx::SF::LineShape)
              case condir
              when CONNECTMODE::STARTING
                opposite = opposite.get_src_shape

                if  opposite.is_a?(Wx::SF::LineShape)
                  opposite.__send__(:_get_neighbours, shape_info, condir, direct, neighbours, processed)
                elsif !neighbours.include?(opposite)
                  neighbours << opposite
                end

              when CONNECTMODE::ENDING
                opposite = opposite.get_trg_shape

                if opposite.is_a?(Wx::SF::LineShape)
                  opposite.__send__(:_get_neighbours, shape_info, condir, direct, neighbours, processed)
                elsif !neighbours.include?(opposite)
                  neighbours << opposite
                end

              when CONNECTMODE::BOTH
                opposite = opposite.get_src_shape
                if opposite.is_a?(Wx::SF::LineShape)
                  opposite.__send__(:_get_neighbours, shape_info, condir, direct, neighbours, processed)
                elsif !neighbours.include?(opposite)
                  neighbours << opposite
                end

                opposite = opposite.get_trg_shape
                if opposite.is_a?(Wx::SF::LineShape)
                  opposite.__send__(:_get_neighbours, shape_info, condir, direct, neighbours, processed)
                elsif !neighbours.include?(opposite)
                  neighbours << opposite
                end
              end
            else
             opposite.__send__(:_get_neighbours, shape_info, condir, direct, neighbours, processed)
            end
          end
        end
      end
    end

    # Auxiliary function called by GetCompleteBoundingBox function.
	  # @param [Wx::Rect] rct bounding rectangle to update
	  # @param [BBMODE] mask Bit mask of object types which should be included into calculation
    # @param [Set<Wx::SF::Shape] processed set to keep track of processed shapes
    # @return [Wx::Rect] bounding rectangle
	  # @see BBMODE
    def _get_complete_bounding_box(rct, mask = BBMODE::ALL, processed = ::Set.new)
      return rct unless @diagram
      return rct if processed.include?(self)

      processed << self

      # first, get bounding box of the current shape
      if mask.allbits?(BBMODE::SELF)
        if rct.is_empty
          rct.assign(get_bounding_box.inflate!(@h_border.abs.to_i, @v_border.abs.to_i))
        else
          rct.union!(get_bounding_box.inflate!(@h_border.abs.to_i, @v_border.abs.to_i))

          # add also shadow offset if necessary
          if mask.allbits?(BBMODE::SHADOW) && has_style?(STYLE::SHOW_SHADOW) && get_parent_canvas
            n_offset = get_parent_canvas.get_shadow_offset

            if n_offset.x < 0
              rct.set_x(rct.x + n_offset.x.to_i)
              rct.set_width(rct.width - n_offset.x.to_i)
            else
              rct.set_width(rct.width + n_offset.x.to_i)
            end

            if n_offset.y < 0
              rct.set_y(rct.y + n_offset.y.to_i)
              rct.set_height(rct.height - n_offset.y.to_i)
            else
              rct.set_height(rct.height + n_offset.y.to_i)
            end
          end
        end
      else
        mask |= BBMODE::SELF
      end

      # get list of all connection lines assigned to the shape and find their child shapes
      lst_children = []
      if mask.allbits?(BBMODE::CONNECTIONS)
        lst_lines = get_assigned_connections(Wx::SF::LineShape, CONNECTMODE::BOTH)

        lst_lines.each do |line|
          # rct.union!(line.get_bounding_box)
          lst_children << line

          # get children of the connections
          line.get_child_shapes(ANY, NORECURSIVE, SEARCHMODE::BFS, lst_children)
        end
      end

      # get children of this shape
      if mask.allbits?(BBMODE::CHILDREN)
        get_child_shapes(ANY, NORECURSIVE, SEARCHMODE::BFS, lst_children)

        # now, call this function for all children recursively...
        lst_children.each do |child|
          child.send(:_get_complete_bounding_box, rct, mask, processed)
        end
      end
      rct
    end

    # Original protected event handler called when the mouse pointer is moving around the shape canvas.
    # The function is called by the framework (by the shape canvas). After processing the event
	  # relevant overridable event handlers are called.
    # @param [Wx::Point] pos Current mouse position
    # @see Wx::SF::Shape#on_mouse_enter
    # @see Wx::SF::Shape#on_mouse_over
    # @see Wx::SF::Shape#on_mouse_leave
    def _on_mouse_move(pos)
      return unless @diagram

      if @visible && @active
        f_update_shape = false
        canvas = get_shape_canvas

        # send the event to the shape handles too...
        @handles.each { |h| h.__send__(:_on_mouse_move, pos) }

        # send the event to the connection points too...
        @connection_pts.each { |cp| cp.__send__(:_on_mouse_move, pos) }

        # determine, whether the shape should be highlighted for any reason
        if canvas
          case canvas.get_mode
          when Wx::SF::ShapeCanvas::MODE::SHAPEMOVE
            if has_style?(STYLE::HIGHLIGHTING) && canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::HIGHLIGHTING)
              shape_under_cursor = canvas.get_shape_under_cursor(Wx::SF::ShapeCanvas::SEARCHMODE::UNSELECTED)
              while shape_under_cursor
                break unless shape_under_cursor.has_style?(STYLE::PROPAGATE_HIGHLIGHTING)
                shape_under_cursor = shape_under_cursor.get_parent_shape
              end
              if shape_under_cursor == self
                f_update_shape = @highlight_parent = accept_currently_dragged_shapes
              end
            end

          when Wx::SF::ShapeCanvas::MODE::HANDLEMOVE
            if has_style?(STYLE::HOVERING) && canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::HOVERING)
              shape_under_cursor = canvas.get_shape_under_cursor(Wx::SF::ShapeCanvas::SEARCHMODE::UNSELECTED)
              while shape_under_cursor
                break unless shape_under_cursor.has_style?(STYLE::PROPAGATE_HOVERING)
                shape_under_cursor = shape_under_cursor.get_parent_shape
              end

              f_update_shape = true if shape_under_cursor == self
              @highlight_parent = false
            end

          else
            if has_style?(STYLE::HOVERING) && canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::HOVERING)
              shape_under_cursor = canvas.get_shape_under_cursor
              while shape_under_cursor
                break unless shape_under_cursor.has_style?(STYLE::PROPAGATE_HOVERING)
                shape_under_cursor = shape_under_cursor.get_parent_shape
              end

              f_update_shape = true if shape_under_cursor == self
              @highlight_parent = false
            end
          end
        end

        if contains?(pos) && f_update_shape
          if !@mouse_over
            @mouse_over = true
            on_mouse_enter(pos)
            refresh(DELAYED)
          else
            on_mouse_over(pos)
          end
        else
          if @mouse_over
            @mouse_over = false
            on_mouse_leave(pos)
            refresh(DELAYED)
          end
        end
      end
    end

    # Original protected event handler called at the beginning of dragging process.
    # The function is called by the framework (by the shape canvas). After processing the event
	  # an overridable event handler is called.
    # @param [Wx::Point] pos Current mouse position
    # @see Wx::SF::Shape#on_begin_drag
    def _on_begin_drag(pos)
      return unless @active

      @first_move = true
      on_begin_drag(pos)

      if @parent_shape && has_style?(STYLE::PROPAGATE_DRAGGING)
        @parent_shape.__send__(:_on_begin_drag, pos)
      end
    end

    # Original protected event handler called during a dragging process.
    # The function is called by the framework (by the shape canvas). After processing the event
	  # an overridable event handler is called.
    # @param [Wx::Point] pos Current mouse position
    # @see Wx::SF::Shape#on_dragging
    def _on_dragging(pos)
      return unless @diagram

      if @visible && @active && has_style?(STYLE::POSITION_CHANGE)
        if @first_move
          @mouse_offset = Wx::RealPoint.new(pos.x, pos.y) - get_absolute_position
        end

        # get shape BB BEFORE movement and combine it with BB of assigned lines
        prev_bb = get_complete_bounding_box(Wx::Rect.new, BBMODE::SELF | BBMODE::CONNECTIONS | BBMODE::CHILDREN | BBMODE::SHADOW)

        move_to(pos.x - @mouse_offset.x, pos.y - @mouse_offset.y)
        on_dragging(pos)

        # GUI controls in child control shapes must be updated explicitly
        lst_child_ctrls = get_child_shapes(Wx::SF::ControlShape, RECURSIVE)
        lst_child_ctrls.each { |ctrl| ctrl.update_control }

        # get shape BB AFTER movement and combine it with BB of assigned lines
        curr_bb = get_complete_bounding_box(Wx::Rect.new, BBMODE::SELF | BBMODE::CONNECTIONS | BBMODE::CHILDREN | BBMODE::SHADOW)

        # update canvas
        refresh_rect(prev_bb.union!(curr_bb), DELAYED)

        @first_move = false
      end

      if @parent_shape && has_style?(STYLE::PROPAGATE_DRAGGING)
        @parent_shape.__send__(:_on_dragging, pos)
      end
    end

    # Original protected event handler called at the end of dragging process.
    # The function is called by the framework (by the shape canvas). After processing the event
	  # an overridable event handler is called.
    # @param [Wx::Point] pos Current mouse position
    # @see Wx::SF::Shape#on_end_drag
    def _on_end_drag(pos)
      return unless @active

      on_end_drag(pos)

      if @parent_shape && has_style?(STYLE::PROPAGATE_DRAGGING)
        @parent_shape.__send__(:_on_end_drag, pos)
      end
    end

    # Original protected event handler called when any key is pressed (in the shape canvas).
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation performs operations necessary for proper shape's
	  # moving and repainting.
	  # @param [Integer] key The key code
	  # @see Wx::SF::Shape#on_key
    def _on_key(key)
      canvas = get_shape_canvas

      return unless canvas

      if @visible && @active
        dx = 1.0
        dy = 1.0
        f_refresh_all = false

        if canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::GRID_USE)
          dx = canvas.get_grid_size.x
          dy = canvas.get_grid_size.y
        end

        lst_selection = canvas.get_selected_shapes
        if (lst_selection.size > 1) && lst_selection.include?(self)
          f_refresh_all = true
        end

        prev_bb = Wx::Rect.new
        unless f_refresh_all
          prev_bb = get_complete_bounding_box(prev_bb, BBMODE::SELF | BBMODE::CONNECTIONS | BBMODE::CHILDREN | BBMODE::SHADOW)
        end

        if on_key(key)
          case key
          when Wx::K_LEFT
            move_by(-dx, 0) if has_style?(STYLE::POSITION_CHANGE)

          when Wx::K_RIGHT
            move_by(dx, 0) if has_style?(STYLE::POSITION_CHANGE)

          when Wx::K_UP
            move_by(0, -dy) if has_style?(STYLE::POSITION_CHANGE)

          when Wx::K_DOWN
            move_by(0, dy) if has_style?(STYLE::POSITION_CHANGE)
          end
        end

        if !f_refresh_all
          curr_bb = get_complete_bounding_box(Wx::Rect.new, BBMODE::SELF | BBMODE::CONNECTIONS | BBMODE::CHILDREN | BBMODE::SHADOW)

          prev_bb.union!(curr_bb)
          refresh_rect(prev_bb, DELAYED)
        else
          canvas.refresh(false)
        end
      end
    end

    # Original protected event handler called during dragging of the shape handle.
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation manages the child shapes' alignment (if set).
	  # @param [Wx::SF::Shape::Handle] handle dragged handle
    def _on_handle(handle)
      return unless @diagram

      if @parent_shape
        prev_bb = get_grand_parent_shape.get_complete_bounding_box(Wx::Rect.new)
      else
        prev_bb = get_complete_bounding_box(Wx::Rect.new)
      end

      # call appropriate user-defined handler
      on_handle(handle)

      # align children
      @child_shapes.each do |child|
        if child.get_v_align != VALIGN::NONE || child.get_h_align != HALIGN::NONE
          child.do_alignment
        end
      end

      # update shape
      update

      if @parent_shape
        curr_bb = get_grand_parent_shape.get_complete_bounding_box(Wx::Rect.new)
      else
        curr_bb = get_complete_bounding_box(Wx::Rect.new)
      end

      # refresh shape
      refresh_rect(curr_bb.union!(prev_bb), DELAYED)
    end

    # Event handler called by ShapeCanvas to request,report canvas changes.
    # Default implementation does nothing.
    # @param [ShapeCanvas::CHANGE] _change change type indicator
    # @param [Array] _args any additional arguments
    # @return [Boolean]
    def _on_canvas(_change, *_args)
      # overridden in some derived shapes
      true
    end

    # Sets accepted children. Exclusively for deserialization.
    def set_accepted_children(set)
      @accepted_children.replace(set.collect { |e| e.is_a?(::String) ? ::Object.const_get(e) : e })
    end

    # Sets accepted connection. Exclusively for deserialization.
    def set_accepted_connections(set)
      @accepted_connections.replace(set.collect { |e| e.is_a?(::String) ? ::Object.const_get(e) : e })
    end

    # Sets accepted src neighbours. Exclusively for deserialization.
    def set_accepted_src_neighbours(set)
      @accepted_src_neighbours.replace(set.collect { |e| e.is_a?(::String) ? ::Object.const_get(e) : e })
    end

    # Sets accepted trg neighbours. Exclusively for deserialization.
    def set_accepted_trg_neighbours(set)
      @accepted_trg_neighbours.replace(set.collect { |e| e.is_a?(::String) ? ::Object.const_get(e) : e })
    end

    # Sets connection points. Exclusively for deserialization.
    def set_connection_points(list)
      @connection_pts.replace(list)
      @connection_pts.each { |cp| cp.parent_shape = self }
    end

    def update_child_parents
      @child_shapes.each do |shape|
        shape.instance_variable_set(:@parent_shape, self)
      end
    end

    # (de-)serialize child shapes. Exclusively for deserialization.
    def serialize_child_shapes(*val)
      unless val.empty?
        @child_shapes = val.first
        # @parent_shape is not serialized, instead we rely on child shapes being (de-)serialized
        # by their parent (child shapes restored before restoring parent child list) and let
        # the parent reset the @parent_shape attributes of their children.
        # That way the links never get out of sync.
        update_child_parents
      end
      @child_shapes
    end

    public

    # Returns intersection point of two lines (if any)
    # @param [Wx::RealPoint] from1
    # @param [Wx::RealPoint] to1
    # @param [Wx::RealPoint] from2
    # @param [Wx::RealPoint] to2
    # @return [Wx::RealPoint,nil] intersection point or nil
    def self.lines_intersection(from1, to1, from2, to2)
      # create line 1 info
      a1 = to1.y - from1.y
      b1 = from1.x - to1.x
      c1 = -a1*from1.x - b1*from1.y

      # create line 2 info
      a2 = to2.y - from2.y
      b2 = from2.x - to2.x
      c2 = -a2*from2.x - b2*from2.y

      # check, whether the lines are parallel...
      ka = a1 / a2
      kb = b1 / b2

      return nil if ka == kb

      xi = (b1*c2 - c1*b2) / (a1*b2 - a2*b1)
      yi = -(a1*c2 - a2*c1) / (a1*b2 - a2*b1)

      if ((from1.x - xi) * (xi - to1.x) >= 0.0) &&
        ((from2.x - xi) * (xi - to2.x) >= 0.0) &&
        ((from1.y - yi) * (yi - to1.y) >= 0.0) &&
        ((from2.y - yi) * (yi - to2.y) >= 0.0)
        return Wx::RealPoint.new(xi, yi)
      end

      nil
    end

    # Allow shapes to call class method as instance method.
    def lines_intersection(*args)
      Shape.lines_intersection(*args)
    end

  end # class Shape

end # module Wx::SF

require 'wx/shapes/shape_handle'

Dir[File.join(__dir__, 'shapes', '*.rb')].each do |f|
  require "wx/shapes/shapes/#{File.basename(f, '.rb')}"
end
