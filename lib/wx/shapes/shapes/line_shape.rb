# Wx::SF::LineShape - line shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrow_base'

module Wx::SF

  class LineShape < Shape

    # Default values
    module DEFAULT
      # Default value of undefined ID. 
      UNKNOWNID = nil
      # Default value of LineShape @pen data member.
      PEN = Wx::Pen.new(Wx::BLACK) if Wx::App.is_main_loop_running
      Wx.add_delayed_constant(self, :PEN) { Wx::Pen.new(Wx::BLACK) }
      # Default value of LineShape @dock_point data member.
      DOCKPOINT = 0
      # Default value of LineShape @dock_point data member (start line point).
      DOCKPOINT_START = -1
      # Default value of LineShape @dock_point data member (end line point).
      DOCKPOINT_END = -2
      # Default value of LineShape @dock_point data member (middle dock point).
      DOCKPOINT_CENTER = 2**64
      # Default value of LineShape @src_offset and LineShape @trg_offset data members.
      OFFSET = Wx::RealPoint.new(-1, -1)
      # Default value of LineShape @src_point and LineShape @trg_point data members.
      POINT = Wx::RealPoint.new(0, 0)
      # Default value of LineShape @stand_alone data member.
      STANDALONE = false
    end

    # The modes in which the line shape can stay.
    class LINEMODE < Wx::Enum
      READY = self.new(0)
      UNDERCONSTRUCTION = self.new(1)
      SRCCHANGE = self.new(2)
      TRGCHANGE = self.new(3)
    end

    property :src_shape_id, :trg_shape_id, :src_point, :trg_point,
             :stand_alone, :src_arrow, :trg_arrow, :src_offset, :trg_offset,
             :dock_point, :line_pen, :control_points

    # @overload initialize()
    #   default constructor
    # @overload initialize(src, trg, path, manager)
    #   @param [Wx::SF::Serializable::ID] src ID of the source shape
    #   @param [Wx::SF::Serializable::ID] trg ID of the target shape
    #   @param [Array<Wx::RealPoint>] path List of the line control points (can be empty)
    #   @param [Diagram] diagram containing diagram
    # @overload initialize(src, trg, path, manager)
    #   @param [Wx::RealPoint] src starting line point
    #   @param [Wx::RealPoint] trg end line point
    #   @param [Array<Wx::RealPoint>,nil] path List of the line control points (can be empty or nil)
    #   @param [Diagram] diagram containing diagram
    def initialize(*args)
      if args.empty?
        super()
        @src_shape_id = @trg_shape_id = DEFAULT::UNKNOWNID
        @src_point = @trg_point = DEFAULT::POINT
        @stand_alone = DEFAULT::STANDALONE
        @lst_points = []
      else
        src, trg, path, diagram = args
        super(Shape::DEFAULT::POSITION, diagram)
        if src.is_a?(Wx::RealPoint) && trg.is_a?(Wx::RealPoint)
          @src_point = src
          @trg_point = trg
          @src_shape_id = @trg_shape_id = DEFAULT::UNKNOWNID
          @stand_alone = true
        elsif src.is_a?(Wx::SF::Serializable::ID) && trg.is_a?(Wx::SF::Serializable::ID)
          @src_point = @trg_point = DEFAULT::POINT
          @src_shape_id = src
          @trg_shape_id = trg
          @stand_alone = false
        else
          ::Kernel.raise ArgumentError, "Invalid arguments #{args}"
        end
        path ||= []
        @lst_points = path.select { |pt| pt.is_a?(Wx::RealPoint) }
        ::Kernel.raise ArgumentError, "Invalid arguments #{args}" unless path.size == @lst_points.size
      end

      @src_arrow = nil
      @trg_arrow = nil

      @dock_point = DEFAULT::DOCKPOINT
      @pen = DEFAULT::PEN

      @src_offset = @trg_offset = DEFAULT::OFFSET

      @mode = LINEMODE::READY
      @prev_position = Wx::RealPoint.new
      @unfinished_point = Wx::Point.new
    end

    # @return [Wx::SF::Serializable::ID]
    def get_src_shape_id
      @src_shape_id
    end
    alias :src_shape_id :get_src_shape_id

    # @param [Wx::SF::Serializable::ID] id
    def set_src_shape_id(id)
      @src_shape_id = id
    end
    alias :src_shape_id= :set_src_shape_id

    # @return [Wx::SF::Serializable::ID]
    def get_trg_shape_id
      @trg_shape_id
    end
    alias :trg_shape_id :get_trg_shape_id

    # @param [Wx::SF::Serializable::ID] id
    def set_trg_shape_id(id)
      @trg_shape_id = id
    end
    alias :trg_shape_id= :set_trg_shape_id

    # @return [Wx::RealPoint]
    def get_src_point
      @src_point
    end
    alias :src_point :get_src_point
    
    # @param [Wx::RealPoint] pt
    def set_src_point(pt)
      @src_point = pt
    end
    alias :src_point= :set_src_point

    # @return [Wx::RealPoint]
    def get_trg_point
      @trg_point
    end
    alias :trg_point :get_trg_point

    # @param [Wx::RealPoint] pt
    def set_trg_point(pt)
      @trg_point = pt
    end
    alias :trg_point= :set_trg_point

    # @return [Wx::SF::ArrowBase]
    def get_src_arrow
      @src_arrow
    end
    alias :src_arrow :get_src_arrow

    # @param [Wx::SF::ArrowBase] arrow
    def set_src_arrow(pt)
      @src_arrow = pt
    end
    alias :src_arrow= :set_src_arrow

    # @return [Wx::SF::ArrowBase]
    def get_trg_arrow
      @trg_arrow
    end
    alias :trg_arrow :get_trg_arrow

    # @param [Wx::SF::ArrowBase] arrow
    def set_trg_arrow(pt)
      @trg_arrow = pt
    end
    alias :trg_arrow= :set_trg_arrow

    # Get line type
    # @return [Wx::Pen]
    def get_line_pen
      @pen
    end
    alias :line_pen :get_line_pen

    # Set line type
    # @param [Wx::Pen] pen line type
    def set_line_pen(pen)
      @pen = pen
    end
    alias :line_pen= :set_line_pen

    # Set the line dock point. It is a zero based index of the line
    # control point which will act as the shape position (value returned by Shape#get_relative_position function).
    # @param [Integer] index Zero based index of the line control point
    def set_dock_point(index)
      @dock_point = index
    end
    alias :dock_point= :set_dock_point

    # Get the line dock point. It is a zero based index of the line
    # control point which will act as the shape position (value returned by Shape#get_relative_position function).
    # @return [Integer] Zero based index of the line control point (-1 means UNDEFINED)
    def get_dock_point
      @dock_point
    end

    # Returns true if stand alone line
    # @return [Boolean]
    def get_stand_alone
      @stand_alone
    end
    alias :stand_alone? :get_stand_alone

    # Set stand alone line mode
    # @param [Boolean] f flag
    def set_stand_alone(f = true)
      @stand_alone = !!f
    end
    alias :stand_alone= :set_stand_alone

	  # Get starting and ending line points.
    # @return [Array(Wx::RealPoint, Wx::RealPoint)] starting line point and ending line point
    def get_direct_line
      if @stand_alone
        return [@src_point, @trg_point]
      else
        src_shape = get_diagram.find_shape(@src_shape_id)
        trg_shape = get_diagram.find_shape(@trg_shape_id)
    
        if src_shape && trg_shape
          trg_center = get_mod_trg_point
          src_center = get_mod_src_point

          if src_shape.get_parent_shape == trg_shape || trg_shape.get_parent_shape == src_shape
            trg_bb = trg_shape.get_bounding_box
            src_bb = src_shape.get_bounding_box

            if trg_bb.contains?(src_center.to_point)
              if src_center.y > trg_center.y
                src = Wx::RealPoint.new(src_center.x, src_bb.bottom.to_f)
                trg = Wx::RealPoint.new(src_center.x, trg_bb.bottom.to_f)
              else
                src = Wx::RealPoint.new(src_center.x, src_bb.top.to_f)
                trg = Wx::RealPoint.new(src_center.x, trg_bb.top.to_f)
              end
              return [src, trg]
            elsif src_bb.contains?(trg_center.to_point)
              if trg_center.y > src_center.y
                src = Wx::RealPoint.new(trg_center.x, src_bb.bottom.to_f)
                trg = Wx::RealPoint.new(trg_center.x, trg_bb.bottom.to_f)
              else
                src = Wx::RealPoint.new(trg_center.x, src_bb.top.to_f)
                trg = Wx::RealPoint.new(trg_center.x, trg_bb.top.to_f)
              end
              return [src, trg]
            end
          end

          if src_shape.get_connection_points.empty?
            src = src_shape.get_border_point(src_center, trg_center)
          else
            src = src_center
          end

          if trg_shape.get_connection_points.empty?
            trg = trg_shape.get_border_point(trg_center, src_center)
          else
            trg = trg_center
          end
          return [src, trg]
        end
      end
      nil # should not happen
    end
    
	  # Get a list of the line's control points (their positions).
	  # @return [Array<Wx::RealPoint>] List of control points' positions
    def get_control_points
      @lst_points
    end

	  # Get a position of given line dock point.
	  # @param [Integer] dp Dock point
	  # @return [Wx::RealPoint] The dock point's position if exists, otherwise the line center
    def get_dock_point_position(dp)
      pts_cnt = @lst_points.size

      if dp >= 0
        if pts_cnt > dp
          return @lst_points[dp]
        elsif pts_cnt > 0
          return @lst_points[pts_cnt/2]
        end
      elsif dp == -1 # start line point
        return get_src_point
      elsif dp == -2  # end line point
        return get_trg_point
      end

      get_center
    end
	
	  # Initialize line's starting point with existing fixed connection point.
	  # @param [Wx::SF::ConnectionPoint] cp Pointer to connection point
    def set_starting_connection_point(cp)
      if cp && cp.get_parent_shape
        pos_cp = cp.get_connection_point
        rct_bb = cp.get_parent_shape.get_bounding_box

        @src_offset.x = (pos_cp.x - rct_bb.left).to_f / rct_bb.width
        @src_offset.y = (pos_cp.y - rct_bb.top).to_f / rct_bb.height
      end
    end

	  # Initialize line's ending point with existing fixed connection point.
	  # @param [Wx::SF::ConnectionPoint] cp Pointer to connection point
    def set_ending_connection_point(cp)
      if cp && cp.get_parent_shape
        pos_cp = cp.get_connection_point
        rct_bb = cp.get_parent_shape.get_bounding_box

        @trg_offset.x = (pos_cp.x - rct_bb.left).to_f / rct_bb.width
        @trg_offset.y = (pos_cp.y - rct_bb.top).to_f / rct_bb.height
      end
    end
	
    # Get starting and ending point of line segment defined by its index.
	  # @param [Integer] index Index of desired line segment
	  # @return [Array(Wx::RealPoint,Wx::RealPoint), nil] starting and ending point of line segment or nil if no line segment of given index exists
    def get_line_segment(index)
      if !@lst_points.empty?
        if index == 0
          return [get_src_point, @lst_points.first.dup]
        elsif index == @lst_points.size
          return [@lst_points.last.dup, get_trg_point]
        elsif index > 0 && index < @lst_points.size
          return @lst_points[index-1, 2].collect {|p| p.dup}
        end
      else
        get_direct_line if index == 0
      end
      nil
    end
    
	  # Get line's bounding box. The function can be overridden if necessary.
    # @return [Wx::Rect] Bounding rectangle
    def get_bounding_box
      line_rct = Wx::Rect.new(0, 0, 0, 0)
    
      # calculate control points area if they exist
      if !@lst_points.empty?
        prev_pt = get_src_point
    
        @lst_points.each do |pt|
          if line_rct.empty?
            line_rct = Wx::Rect.new(prev_pt.to_point, pt.to_point)
          else
            line_rct.union(Wx::Rect.new(prev_pt.to_point, pt.to_point))
          end
          prev_pt = pt
        end
    
        line_rct.union(Wx::Rect.new(prev_pt.to_point, get_trg_point.to_point))
      else
        # include starting point
        pt = get_src_point

        if line_rct.empty?
          line_rct = Wx::Rect.new(pt.x.to_i, pt.y.to_i, 1, 1)
        else
          line_rct.union(Wx::Rect.new(pt.x.to_i, pt.y.to_i, 1, 1))
        end
    
        # include ending point
        pt = get_trg_point
        if line_rct.empty?
          line_rct = Wx::Rect.new(pt.x.to_i, pt.y.to_i, 1, 1)
        else
          line_rct.union(Wx::Rect.new(pt.x.to_i, pt.y.to_i, 1, 1))
        end
      end
    
      # include unfinished point if the line is under construction
      if @mode == LINEMODE::UNDERCONSTRUCTION || @mode == LINEMODE::SRCCHANGE || @mode == LINEMODE::TRGCHANGE
        if line_rct.empty?
          line_rct = Wx::Rect.new(@unfinished_point.x, @unfinished_point.y, 1, 1)
        else
          line_rct.union(Wx::Rect.new(@unfinished_point.x, @unfinished_point.y, 1, 1))
        end
      end
    
      line_rct
    end

	  # Get the shape's absolute position in the canvas.
	  # @return [Wx::RealPoint] Shape's position
    def get_absolute_position
    end

	  # Get intersection point of the shape border and a line leading from
	  # 'start_pt' point to 'end_pt' point. The function can be overridden if necessary.
	  # @param [Wx::RealPoint] start_pt Starting point of the virtual intersection line
    # @param [Wx::RealPoint] end_pt Ending point of the virtual intersection line
	  # @return [Wx::RealPoint] Intersection point
    def get_border_point(start_pt, end_pt)

    end

	  # Test whether the given point is inside the shape. The function
    # can be overridden if necessary.
    # @param pos Examined point
    # @return TRUE if the point is inside the shape area, otherwise FALSE
    def contains?(pos)

    end

	  # Move the shape to the given absolute position. The function
    # can be overridden if necessary.
	  # @param [Float] x X coordinate
	  # @param [Float] y Y coordinate
    def move_to(x, y)

    end

	  # Move the shape by the given offset. The function
    #  can be overridden if necessary.
	  # @param [Float] x X offset
	  # @param [Float] y Y offset
    def move_by(x, y)

    end

	  # Function called by the framework responsible for creation of shape handles
    # at the creation time. The function can be overridden if neccesary.
    def create_handles

    end

	  # Event handler called during dragging of the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # @param [Wx::SF::Shape::Handle] handle Reference to dragged handle
    def on_handle(handle)

    end

	  # Event handler called when the user finished dragging of the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation does nothing.
    # @param [Wx::SF::Shape::Handle] handle Reference to dragged handle
    def on_end_handle(handle)

    end

	  # Event handler called at the beginning of the shape dragging process.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
    # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_begin_drag(pos)

    end

	  # Event handler called when the shape is double-clicked by
	  # the left mouse button. The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
    # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_left_double_click(pos)

    end

	  # Scale the shape size by in both directions. The function can be overridden if necessary
    # (new implementation should call default one ore scale shape's children manualy if neccesary).
    # @param [Float] x Horizontal scale factor
    # @param [Float] y Vertical scale factor
    # @param [Boolean] children true if the shape's children should be scaled as well, otherwise the shape will be updated after scaling via update() function.
    def scale(x, y, children = WITHCHILDREN)

    end

    protected

	  # Draw the shape in the normal way. The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)

    end

	  # Draw the shape in the hower mode (the mouse cursor is above the shape).
    # The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)

    end

	  # Draw the shape in the highlighted mode (another shape is dragged over this
    # shape and this shape will accept the dragged one if it will be dropped on it).
    # The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_highlighted(dc)

    end

    # Draw completed line.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_complete_line(dc)

    end

    # Get index of the line segment intersecting the given point.
	  # @param [Wx::Point] pos Examined point
	  # @return [Integer] Zero-based index of line segment located under the given point
    def get_hit_linesegment(pos)

    end

    # Set line shape's working mode.
    # @param [LINEMODE] mode Working mode
    # @see LINEMODE
    def set_line_mode(mode)
      @mode = mode
    end

    # Get current working mode.
	  # @return [LINEMODE] Current working mode
    # @see LINEMODE
    def get_line_mode
      @mode
    end

    # Set next potential control point position (useful in LINEMODE::UNDERCONSTRUCTION working mode).
	  # @param [Wx::Point] pos New potential control point position
    # @see LINEMODE
    def set_unfinished_point(pos)
      @unfinished_point = pos
    end

    # Get modified starting line point .
	  # @return [Wx::RealPoint] Modified starting line point
    def get_mod_src_point

    end

    # Get modified ending line point .
	  # @return [Wx::RealPoint] Modified ending line point
    def get_mod_trg_point

    end

    private

    # Set control points. Deserialization only.
    # @param [Array<Wx::RealPoint>] pts
    def set_control_points(pts)
      @lst_points.replace(pts)
    end

    # Serialization only
    # @return [Wx::RealPoint]
    def get_src_offset
      @src_offset
    end

    # Deserialization only
    # @param [Wx::RealPoint] offs
    def set_src_offset(offs)
      @src_offset = offs
    end

    # Serialization only
    # @return [Wx::RealPoint]
    def get_trg_offset
      @trg_offset
    end

    # Deserialization only
    # @param [Wx::RealPoint] offs
    def set_trg_offset(offs)
      @trg_offset = offs
    end

  end

end
