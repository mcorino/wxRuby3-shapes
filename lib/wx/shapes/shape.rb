# Wx::SF::Shape - base shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/serializable'

require 'set'

module Wx::SF

  RECURSIVE = true
  NORECURSIVE = false
  DIRECT = true
  INDIRECT = false
  WITHCHILDREN = true
  WITHOUTCHILDREN = false
  ANY = nil
  DELAYED = true
  
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

    include Serializable

    property :id, :active, :visibility, :style,
             :accepted_children, :accepted_connections,
             :accepted_src_neighbours, :accepted_trg_neighbours,
             :hover_colour, :relative_position,
             :h_align, :v_align, :h_border, :v_border,
             :custom_dock_point, :connection_points,
             :user_data

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
      # User data is destroyed at the shape deletion
      DELETE_USER_DATA = self.new(64)
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
      DEFAULT_SHAPE_STYLE = PARENT_CHANGE | POSITION_CHANGE | SIZE_CHANGE | HOVERING | HIGHLIGHTING | SHOW_HANDLES | ALWAYS_INSIDE | DELETE_USER_DATA
    end

    # Default values
    module DEFAULT
      # Default value of Wx::SF::Shape @visible data member
      VISIBILITY = true
      # Default value of Wx::SF::Shape @active data member
      ACTIVITY = true
      # Default value of Wx::SF::Shape @hoverColor data member
      HOVERCOLOUR = Wx::Colour.new(120, 120, 255) if Wx.is_main_loop_running
      Wx.add_delayed_constant(self, :HOVERCOLOUR) { Wx::Colour.new(120, 120, 255) }
      # Default value of Wx::SF::Shape @relativePosition data member
      POSITION = Wx::RealPoint.new(0, 0) if Wx.is_main_loop_running
      Wx.add_delayed_constant(self, :POSITION) { Wx::RealPoint.new(0, 0) }
      # Default value of Wx::SF::Shape @vAlign data member
      VALIGN = VALIGN::NONE
      # Default value of Wx::SF::Shape @hAlign data member
      HALIGN = HALIGN::NONE
      # Default value of Wx::SF::Shape @vBorder data member
      VBORDER = 0.0
      # Default value of Wx::SF::Shape @hBorder data member
      HBORDER = 0.0
      # Default value of Wx::SF::Shape @style data member
      DEFAULT_STYLE = STYLE::DEFAULT_STYLE
      # Default value of Wx::SF::Shape @customDockPoint data member
      DOCK_POINT = -3
    end

    # @overload initialize()
    #   default constructor
    # @overload initialize(pos, manager)
    #   @param [Wx::Point] pos Initial relative position
    #   @param [Diagram] diagram containing diagram
    def initialize(*args)
      pos, diagram = *args
      ::Kernel.raise ArgumentError, "Invalid arguments pos: #{pos}, diagram: #{diagram}" unless
        args.empty? || (Wx::RealPoint === pos && Wx::SF::Diagram === diagram)

      @id = args.empty? ? nil : Serializable::ID.new
      @diagram = diagram
      @parent_shape = nil
      @child_shapes = []

      if @diagram
        if @diagram.shape_canvas
          @hover_color = @diagram.shape_canvas.hover_colour
        else
          @hover_color = DEFAULT::HOVERCOLOUR;
        end
      else
        @hover_color = DEFAULT::HOVERCOLOUR;
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

      if pos && get_parent_shape
        @relative_position = pos - get_parent_absolute_position
      else
        @relative_position = DEFAULT::POSITION
      end

      @handles = []
      @connection_pts = []

      @accepted_children = ::Set.new
      @accepted_connections = ::Set.new
      @accepted_src_neighbours = ::Set.new
      @accepted_trg_neighbours = ::Set.new
    end

    # Refresh (redraw) the shape
    # @param [Boolean] delayed If true then the shape canvas will be rather invalidated than refreshed.
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
    def contains(pos)
      # HINT: overload it for custom actions...

      get_bounding_box.contains(pos)
    end
    alias :contains? :contains

    # Test whether the shape is completely inside given rectangle. The function
    # can be overridden if necessary.
    # @param [Wx::Rect] rct Examined rectangle
    # @return [Boolean] true if the shape is completely inside given rectangle, otherwise false
    def is_inside(rct)
      # HINT: overload it for custom actions...

      rct.contains(get_bounding_box)
    end
    alias inside? :is_inside

    # Test whether the given rectangle intersects the shape.
    # @param [Wx::Rect] rct Examined rectangle
    # @return [Boolean] true if the examined rectangle intersects the shape, otherwise false
    def intersects(rct)
      # HINT: overload it for custom actions...

      rct.intersects(get_bounding_box)
    end
    alias intersects? :intersects

    # Get the shape's absolute position in the canvas (calculated as a summation
    # of all relative positions in the shapes' hierarchy. The function can be overridden if necessary.
    # @return [Wx::RealPoint] Shape's position
	  def get_absolute_position
      # HINT: overload it for custom actions...

      parent_shape = get_parent_shape
      if parent_shape
        @relative_position + get_parent_absolute_position
      else
        @relative_position
      end
    end
    alias absolute_position :get_absolute_position

    # Get intersection point of the shape border and a line leading from
    # 'start' point to 'finish' point.  Default implementation does nothing. The function can be overridden if necessary.
    # @param [Wx::RealPoint] _start Starting point of the virtual intersection line
    # @param [Wx::RealPoint] _finish Ending point of the virtual intersection line
    # @return [Wx::RealPoint] Intersection point
    def get_border_point(_start, _finish)
      # HINT: overload it for custom actions...
      Wx::RealPoint.new
    end
    alias :border_point :get_border_point

    # Get shape's center. Default implementation does nothing. The function can be overridden if necessary.
    # @return [Wx::RealPoint] Center point
    def get_center
      # HINT: overload it for custom actions...

      bb = get_bounding_box
      Wx::RealPoint.new(bb.left + bb.width/2, bb.top + bb.height/2)
    end

    alias :center :get_center

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
    # Default value is STYLE::PARENT_CHANGE | STYLE::POSITION_CHANGE | STYLE::SIZE_CHANGE | STYLE::HOVERING | STYLE::HIGHLIGHTING | STYLE::SHOW_HANDLES | STYLE::ALWAYS_INSIDE | STYLE::DELETE_USER_DATA
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

      x, y = (args.first.is_a?(Wx::RealPoint) ? args.first : args)
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
          shape.set_relative_position(shape.relative_position.x*x, shape.relative_position.y*y)
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

      pos = (args.first.is_a?(Wx::RealPoint) ? args.first : Wx::RealPoint.new(*args))
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

      x, y = (args.first.is_a?(Wx::RealPoint) ? args.first : args)
      @relative_position.x += x
      @relative_position.y += y

      @diagram.set_modified(true) if @diagram
    end

    # Update the shape's position in order to its alignment
    def do_alignment
      parent = get_parent_shape

      if parent && !parent.is_a?(Wx::SF::GridShape)

        if parent.is_a?(Wx::SF::LineShape)
          line_pos = get_parent_absolute_position
          parent_bb = Wx::Rect.new(line_pos.x.to_i, line_pos.y.to_i, 1, 1)
        else
          parent_bb = parent.get_bounding_box
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
          if parent.is_a?(Wx::SF::LineShape)
            line_start, line_end = parent.get_line_segment(0)

            if line_end.y >= line_start.y
              @relative_position.y = line_start.y - line_pos.y + @v_border
            else
              @relative_position.y = line_start.y - line_pos.y - shape_bb.height - @v_border
            end
          end

        when VALIGN::LINE_END
          if parent.is_a?(Wx::SF::LineShape)
            line_start, line_end = parent.get_line_segment(parent.get_control_points.get_count)

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
          if parent.is_a?(Wx::SF::LineShape)
            line_start, line_end = parent.get_line_segment(0)

            if line_end.x >= line_start.x

              @relative_position.x = line_start.x - line_pos.x + @h_border
            else
              @relative_position.x = line_start.x - line_pos.x - shape_bb.width - @h_border
            end
          end

        when HALIGN::LINE_END
          if parent.is_a?(Wx::SF::LineShape)
            line_start, line_end = parent.get_line_segment(parent.get_control_points.get_count)

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
	    if parent = get_parent_shape
        parent.update
      end
    end

    # Resize the shape to bound all child shapes. The function can be overridden if necessary.
    def fit_to_children
      # HINT: overload it for custom actions...
    end

    # Function returns true if the shape is selected, otherwise returns false
    def is_selected
      @selected
    end
    alias :selected? :is_selected

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
      x, y = (arg.size == 1 ? arg.first : arg)
      @relative_position.x = x
      @relative_position.y = y
    end
    alias :relative_position= :set_relative_position

    # Get shape's relative position.
    # @return [Wx::RealPoint] Current relative position
    # @see #get_absolute_position
    def get_relative_position
      @relative_position
    end
    alias :relative_position :get_relative_position

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

    # Get parent shape
    # @return [Wx::SF::Shape,nil] parent shape
    def get_parent_shape
      return nil unless @diagram
      @parent_shape
    end
    alias :parent_shape :get_parent_shape

    # Get pointer to the topmost parent shape
    # @return [Wx::SF::Shape] topmost parent shape
    def get_grand_parent_shape
      return nil unless @diagram
      @parent_shape ? @parent_shape.get_parent_shape : self
    end
    alias :grand_parent_shape :get_grand_parent_shape

	  # Determine whether this shape is ancestor of given child shape.
	  # @param [Wx::SF::Shape] child child shape.
	  # @return true if this shape is parent of given child shape, otherwise false
    def is_ancestor(child)
      lst_children = get_child_shapes(nil, RECURSIVE)

      lst_children.include?(child)
    end
    alias :ancestor? :is_ancestor

	  # Determine whether this shape is descendant of given parent shape.
	  # @param [Wx::SF::Shape] parent parent shape
	  # @return true if this shape is a child of given parent shape, otherwise false
    def is_descendant(parent)
      return false unless parent
      lst_children = parent.get_child_shapes(nil, RECURSIVE)

      lst_children.include?(self)
    end
    alias :descendant? :is_descendant

    # Associate user data with the shape.
    # If the data object is properly set then its marked properties will be serialized
    # together with the parent shape. This means the user data must either be a serializable
    # core type or a Wx::SF::Serializable.
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

	  # Get shape's parent diagram
    # @return [Wx::SF::Diagram,nil] diagram
    # @see Wx::SF::Diagram
    def get_diagram
      @diagram
    end
    alias :get_shape_manager :get_diagram
    alias :diagram :get_diagram
    alias :shape_manager :get_diagram

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
    def is_visible
      @visible
    end
    alias :visible? :is_visible
    alias :visibility :is_visible

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
    def is_active
      @active
    end
    alias :active? :is_active
    alias :active :is_active

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
    # @param [String] type Class name of examined shape object
    # @return [Boolean] true if the shape type is accepted, otherwise false.
    def is_child_accepted(type)
      @accepted_children.include?(type) || @accepted_children.include?('*')
    end
    alias :child_accepted? :is_child_accepted

    # Returns true if *all* currently dragged shapes can be accepted
    # as children of this shape.
    # @return [Boolean]
    # @see #is_shape_accepted
    def accept_currently_dragged_shapes
      return false unless get_shape_canvas

      unless is_child_accepted('*')
        lst_selection = get_shape_canvas.get_selected_shapes

        return false if lst_selection.any? { |shape| !@accepted_children.include?(shape.class.name) }
      end
      true
    end

    # Add given shape type to an acceptance list. The acceptance list contains class
    # names of the shapes which can be accepted as children of this shape.
    # Note: Keyword '*' behaves like any class name.
    # @param [String] type Class name of accepted shape object
    # @see #is_child_accepted
    def accept_child(type)
      @accepted_children << type
    end

    # Get shape types acceptance list.
	  # @return [Set<String>] String set with class names of accepted shape types.
	  # @see #is_child_accepted
    def get_accepted_children
      @accepted_children
    end
    alias :accepted_children :get_accepted_children

    # Tells whether the given connection type is accepted by this shape (it means
    # whether this shape can be connected to another one by a connection of given type).
    #
    # The function is typically used by the framework during interactive connection creation.
    # @param [String] type Class name of examined connection object
    # @return true if the connection type is accepted, otherwise false.
    def is_connection_accepted(type)
      @accepted_connections.include?(type) || @accepted_connections.include?('*')
    end
    alias :connection_accepted? :is_connection_accepted

    # Add given connection type to an acceptance list. The acceptance list contains class
    # names of the connection which can be accepted by this shape.
    # Note: Keyword '*' behaves like any class name.
    # @param [String] type Class name of accepted connection object
    # @see #is_connection_accepted
    def accept_connection(type)
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
    # @param [String] type Class name of examined connection object
    # @return true if the shape type is accepted, otherwise false.
    def is_src_neighbour_accepted(type)
      @accepted_src_neighbours.include?(type) || @accepted_src_neighbours.include?('*')
    end
    alias :src_neighbour_accepted? :is_src_neighbour_accepted

    # Add given shape type to an source neighbours' acceptance list. The acceptance list contains class
    # names of the shape types which can be accepted by this shape as its source neighbour.
    # Note: Keyword '*' behaves like any class name.
    # @param [String] type Class name of accepted connection object
    # @see #is_src_neighbour_accepted
    def accept_src_neighbour(type)
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
    # @param [String] type Class name of examined connection object
    # @return [Boolean] true if the shape type is accepted, otherwise false.
    def is_trg_neighbour_accepted(type)
      @accepted_trg_neighbours.include?(type) || @accepted_trg_neighbours.include?('*')
    end
    alias :trg_neighbour_accepted? :is_trg_neighbour_accepted

    # Add given shape type to an target neighbours' acceptance list. The acceptance list contains class
    # names of the shape types which can be accepted by this shape as its target neighbour.
    # Note: Keyword '*' behaves like any class name.
    # @param [String] type Class name of accepted connection object
    # @see #is_trg_neighbour_accepted
    def accept_trg_neighbour(type)
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
	  #   @return [Wx::SF::ConnectionPoint,nil] new connection point
    # @overload add_connection_point(relpos, id=-1, persistent: true)
    #   @param [Wx::RealPoint] relpos Relative position in percentages
    #   @param [Integer] id connection point ID
    #   @param [Boolean] persistent true if the connection point should be serialized
    #   @return [Wx::SF::ConnectionPoint,nil] new connection point
    # @overload add_connection_point(cp, persistent: true)
    #   @param [Wx::SF::ConnectionPoint] cp connection point (shape will take the ownership)
    #   @param [Boolean] persistent true if the connection point should be serialized
    #   @return [Wx::SF::ConnectionPoint,nil] added connection point
	  # @see Wx::SF::ConnectionPoint::CPTYPE
    def add_connection_point(arg, *rest, persistent: true)
      cp = nil
      case arg
      when ConnectionPoint::CPTYPE
        unless get_connection_point(arg)
          cp = ConnectionPoint.new(self, type)
          cp.disable_list_serialize unless persistent
        end
      when Wx::RealPoint
        cp = ConnectionPoint.new(self, arg, *rest)
        cp.disable_list_serialize unless persistent
      when ConnectionPoint
        cp = arg
        cp.disable_list_serialize unless persistent
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
	  # Default implementation emits Wx::EVT_SF_SHAPE_LEFT_DOWN event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_left_click(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_LEFT_DOWN, self.id.to_i)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when the shape is clicked by
	  # the right mouse button. The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_RIGHT_DOWN event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_right_click(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_RIGHT_DOWN, self.id.to_i)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when the shape is double-clicked by
	  # the left mouse button. The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_LEFT_DCLICK event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_left_double_click(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_LEFT_DCLICK, self.id.to_i)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when the shape is double-clicked by
	  # the right mouse button. The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_RIGHT_DCLICK event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_right_double_click(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_RIGHT_DCLICK, self.id.to_i)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end

    # Event handler called at the beginning of the shape dragging process.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_DRAG_BEGIN event.
    # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_begin_drag(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_DRAG_BEGIN, self.id.to_i)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called during the shape dragging process.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_DRAG event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_dragging(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_DRAG, self.id.to_i)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called at the end of the shape dragging process.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_DRAG_END event.
	  # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_end_drag(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_DRAG_END, self.id.to_i)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end

    # Event handler called when the user started to drag the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_HANDLE_BEGIN event.
	  # @param [Wx::SF::Shape::Handle] handle dragged handle
    def on_begin_handle(handle)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeHandleEvent.new(Wx::SF::EVT_SF_SHAPE_HANDLE_BEGIN, self.id.to_i)
        evt.set_shape(self)
        evt.set_handle(handle)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called during dragging of the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_HANDLE event.
    # @param [Wx::SF::Shape::Handle] handle dragged handle
    def on_handle(handle)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeHandleEvent.new(Wx::SF::EVT_SF_SHAPE_HANDLE, self.id.to_i)
        evt.set_shape(self)
        evt.set_handle(handle)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when the user finished dragging of the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_HANDLE_END event.
    # @param [Wx::SF::Shape::Handle] handle dragged handle
    def on_end_handle(handle)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeHandleEvent.new(Wx::SF::EVT_SF_SHAPE_HANDLE_END, self.id.to_i)
        evt.set_shape(self)
        evt.set_handle(handle)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when a mouse pointer enters the shape area.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_MOUSE_ENTER event.
	  # @param [Wx::Point] pos Current mouse position
    def on_mouse_enter(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_MOUSE_ENTER, self.id.to_i)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when a mouse pointer moves above the shape area.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_MOUSE_OVER event.
	  # @param [Wx::Point] pos Current mouse position
    def on_mouse_over(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_MOUSE_OVER, self.id.to_i)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end
    
    # Event handler called when a mouse pointer leaves the shape area.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_MOUSE_LEAVE event.
	  # @param [Wx::Point] pos Current mouse position
    def on_mouse_leave(pos)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeMouseEvent.new(Wx::SF::EVT_SF_SHAPE_MOUSE_LEAVE, self.id.to_i)
        evt.set_shape(self)
        evt.set_mouse_position(pos)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end

    # Event handler called when any key is pressed (in the shape canvas).
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_KEYDOWN event.
	  # @param [Integer] key The key code
	  # @return The function must return true if the default event routine should be called
	  #         as well, otherwise false
	  # @see Wx::SF::Shape::_on_key
    def on_key(key)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeKeyEvent.new(Wx::SF::EVT_SF_SHAPE_MOUSE_LEAVE, self.id.to_i)
        evt.set_shape(self)
        evt.set_key_code(key)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end

    # Event handler called when any shape is dropped above this shape (and the dropped
	  # shape is accepted as a child of this shape). The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation emits Wx::EVT_SF_SHAPE_CHILD_DROP event.
	  # @param [Wx::RealPoint] _pos Relative position of dropped shape
	  # @param [Wx::SF::Shape] child dropped shape
    def on_child_dropped(_pos, child)
      # HINT: overload it for custom actions...

      if has_style?(STYLE::EMIT_EVENTS) && get_shape_canvas
        evt = Wx::SF::ShapeChildDropEvent.new(Wx::SF::EVT_SF_SHAPE_CHILD_DROP, self.id.to_i)
        evt.set_shape(self)
        evt.set_child_shape(child)
        get_shape_canvas.get_event_handler.process_event(evt)
      end
    end

    protected

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
        @handles.each { |h| h.draw(dc) }
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
      if parent = get_parent_shape
        if parent.is_a?(Wx::SF::LineShape) && @custom_dock_point != DEFAULT::DOCK_POINT
          return parent.get_dock_point_position(@custom_dock_point)
        else
          return parent.get_absolute_position
        end
      end

      Wx::RealPoint.new(0, 0)
    end

    private

    # Auxiliary function called by GetNeighbours function.
	  # @param [Class,nil] shapeInfo Line object type
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
            opposite = @diagram.find_shape(line.get_trg_shape_id)

          when CONNECTMODE::ENDING
            opposite = @diagram.find_shape(line.get_src_shape_id)

          when CONNECTMODE::BOTH
            if @id == line.get_src_shape_id
              opposite = @diagram.find_shape(line.get_trg_shape_id)
            else
              opposite = @diagram.find_shape(line.get_src_shape_id)
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
                opposite = @diagram.find_shape(opposite.get_src_shape_id)

                if  opposite.is_a?(Wx::SF::LineShape)
                  opposite.__send__(:_get_neighbours, shape_info, condir, direct, neighbours, processed)
                elsif !neighbours.include?(opposite)
                  neighbours << opposite
                end

              when CONNECTMODE::ENDING
                opposite = @diagram.find_shape(opposite.get_trg_shape_id)

                if opposite.is_a?(Wx::SF::LineShape)
                  opposite.__send__(:_get_neighbours, shape_info, condir, direct, neighbours, processed)
                elsif !neighbours.include?(opposite)
                  neighbours << opposite
                end

              when CONNECTMODE::BOTH
                opposite = @diagram.find_shape(opposite.get_src_shape_id)
                if opposite.is_a?(Wx::SF::LineShape)
                  opposite.__send__(:_get_neighbours, shape_info, condir, direct, neighbours, processed)
                elsif !neighbours.include?(opposite)
                  neighbours << opposite
                end

                opposite = @diagram.find_shape(opposite.get_trg_shape_id)
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
      return if @diagram
      return if processed.include?(self)

      processed << self

      # first, get bounding box of the current shape
      if (mask & BBMODE::SELF) != 0
        if rct.is_empty
          rct = get_bounding_box.inflate(@h_border.abs, @v_border.abs)
        else
          rct.union(get_bounding_box.inflate(@h_border.abs, @v_border.abs))

          # add also shadow offset if necessary
          if (mask & BBMODE::SHADOW) != 0 && has_style?(STYLE::SHOW_SHADOW) && get_parent_canvas
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
      if (mask & BBMODE::CONNECTIONS) != 0
        lst_lines = get_assigned_connections(Wx::SF::LineShape, CONNECTMODE::BOTH)

        lst_lines.each do |line|
          # rct.union(line.get_bounding_box)
          lst_children << line

          # get children of the connections
          line.get_child_shapes(ANY, NORECURSIVE, SEARCHMODE::BFS, lst_children)
        end
      end

      # get children of this shape
      if (mask & BBMODE::CHILDREN) != 0
        get_child_shapes(ANY, NORECURSIVE, SEARCHMODE::BFS, lst_children)

        # now, call this function for all children recursively...
        lst_children.each do |child|
          child._get_complete_bounding_box(rct, mask, processed)
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

    end

    # Original protected event handler called at the beginning of dragging process.
    # The function is called by the framework (by the shape canvas). After processing the event
	  # an overridable event handler is called.
    # @param [Wx::Point] pos Current mouse position
    # @see Wx::SF::Shape#on_begin_drag
    def _on_begin_drag(pos)

    end

    # Original protected event handler called during a dragging process.
    # The function is called by the framework (by the shape canvas). After processing the event
	  # an overridable event handler is called.
    # @param [Wx::Point] pos Current mouse position
    # @see Wx::SF::Shape#on_dragging
    def _on_dragging(pos)

    end

    # Original protected event handler called at the end of dragging process.
    # The function is called by the framework (by the shape canvas). After processing the event
	  # an overridable event handler is called.
    # @param [Wx::Point] pos Current mouse position
    # @see Wx::SF::Shape#on_end_drag
    def _on_end_drag(pos)

    end

    # Original protected event handler called when any key is pressed (in the shape canvas).
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation performs operations necessary for proper shape's
	  # moving and repainting.
	  # @param [Integer] key The key code
	  # @see Wx::SF::Shape#on_key
    def _on_key(key)

    end

    # Original protected event handler called during dragging of the shape handle.
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation manages the child shapes' alignment (if set).
	  # @param [Wx::SF::Shape::Handle] handle dragged handle
    def _on_handle(handle)

    end

    # Sets accepted children. Exclusively for deserialization.
    def set_accepted_children(set)
      @accepted_children.replace(set)
    end
    private :set_accepted_children

    # Sets accepted connection. Exclusively for deserialization.
    def set_accepted_connections(set)
      @accepted_connections.replace(set)
    end
    private :set_accepted_connections

    # Sets accepted src neighbours. Exclusively for deserialization.
    def set_accepted_src_neighbours(set)
      @accepted_src_neighbours.replace(set)
    end
    private :set_accepted_src_neighbours

    # Sets accepted trg neighbours. Exclusively for deserialization.
    def set_accepted_trg_neighbours(set)
      @accepted_trg_neighbours.replace(set)
    end
    private :set_accepted_trg_neighbours

    # Sets connection points. Exclusively for deserialization.
    def set_connection_points(list)
      @connection_pts.replace(list)
    end
    private :set_connection_points

  end

end

require 'wx/shapes/shape_handle'

Dir[File.join(__dir__, 'shapes', '*.rb')].each do |f|
  require "wx/shapes/shapes/#{File.basename(f, '.rb')}"
end