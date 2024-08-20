# Wx::SF::LineShape - line shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrow_base'

module Wx::SF

  class LineShape < Shape

    # Default values
    module DEFAULT
      class << self
        # Default value of LineShape @pen data member.
        def pen; Wx::Pen.new(Wx::BLACK); end
     end
      # Default value of undefined ID. 
      UNKNOWNID = nil
      # Default value of LineShape @dock_point data member.
      DOCKPOINT = 0
      # Default value of LineShape @dock_point data member (start line point).
      DOCKPOINT_START = -1
      # Default value of LineShape @dock_point data member (end line point).
      DOCKPOINT_END = -2
      # Default value of LineShape @dock_point data member (middle dock point).
      DOCKPOINT_CENTER = (2**64).to_i
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

    property :src_shape_id, :trg_shape_id
    property src_point: :serialize_src_point, trg_point: :serialize_trg_point
    property :stand_alone, :src_arrow, :trg_arrow, :src_offset, :trg_offset,
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
        @src_point = DEFAULT::POINT.dup
        @trg_point = DEFAULT::POINT.dup
        @stand_alone = DEFAULT::STANDALONE
        @lst_points = []
      else
        src, trg, path, diagram = args
        super(Shape::DEFAULT::POSITION.dup, diagram)
        if src.respond_to?(:to_real_point) && trg.respond_to?(:to_real_point)
          @src_point = src.to_real_point
          @trg_point = trg.to_real_point
          @src_shape_id = @trg_shape_id = DEFAULT::UNKNOWNID
          @stand_alone = true
        elsif src.is_a?(Wx::SF::Serializable::ID) && trg.is_a?(Wx::SF::Serializable::ID)
          @src_point = DEFAULT::POINT.dup
          @trg_point = DEFAULT::POINT.dup
          @src_shape_id = src
          @trg_shape_id = trg
          @stand_alone = false
        else
          ::Kernel.raise ArgumentError, "Invalid arguments #{args}"
        end
        path ||= []
        @lst_points = path.select { |pt| pt.respond_to?(:to_real_point) }.collect { |pt| pt.to_real_point }
        ::Kernel.raise ArgumentError, "Invalid arguments #{args}" unless path.size == @lst_points.size
      end

      @src_arrow = nil
      @trg_arrow = nil

      @dock_point = DEFAULT::DOCKPOINT
      @pen = DEFAULT.pen

      @src_offset = DEFAULT::OFFSET.dup
      @trg_offset = DEFAULT::OFFSET.dup

      @mode = LINEMODE::READY
      @prev_position = Wx::RealPoint.new
      @unfinished_point = Wx::Point.new
    end

    # Get source shape id.
    # @return [Wx::SF::Serializable::ID]
    def get_src_shape_id
      @src_shape_id
    end
    alias :src_shape_id :get_src_shape_id

    # Set source shape id.
    # @param [Wx::SF::Serializable::ID] id
    def set_src_shape_id(id)
      @src_shape_id = id
    end
    alias :src_shape_id= :set_src_shape_id

    # Get target shape id.
    # @return [Wx::SF::Serializable::ID]
    def get_trg_shape_id
      @trg_shape_id
    end
    alias :trg_shape_id :get_trg_shape_id

    # Set target shape id.
    # @param [Wx::SF::Serializable::ID] id
    def set_trg_shape_id(id)
      @trg_shape_id = id
    end
    alias :trg_shape_id= :set_trg_shape_id

    # Get source point.
    # @return [Wx::RealPoint]
    def get_src_point
      unless @stand_alone
        src_shape = @diagram.find_shape(@src_shape_id)

        if src_shape && !@lst_points.empty?
          if src_shape.get_connection_points.empty?
            return src_shape.get_border_point(get_mod_src_point, @lst_points.first)
          else
            return get_mod_src_point
          end
        else
          if @mode != LINEMODE::UNDERCONSTRUCTION
            pt1, _ = get_direct_line
          else
            pt1 = get_mod_src_point
          end
          return pt1
        end

        return Wx::RealPoint.new
      end
      @src_point
    end
    alias :src_point :get_src_point

    # Set source point.
    # @param [Wx::RealPoint] pt
    def set_src_point(pt)
      @src_point = pt.to_real_point
    end

    # Get target point.
    # @return [Wx::RealPoint]
    def get_trg_point
      unless @stand_alone
        trg_shape = @diagram.find_shape(@trg_shape_id)

        if trg_shape && !@lst_points.empty?
          if trg_shape.get_connection_points.empty?
            return trg_shape.get_border_point(get_mod_trg_point, @lst_points.last)
          else
            return get_mod_trg_point
          end
        else
          if @mode != LINEMODE::UNDERCONSTRUCTION
            _, pt2 = get_direct_line
          else
            pt2 = @unfinished_point.to_real
          end
          return pt2
        end

        return Wx::RealPoint.new
      end
      @trg_point
    end
    alias :trg_point :get_trg_point

    # Set target point.
    # @param [Wx::RealPoint] pt
    def set_trg_point(pt)
      @trg_point = pt.to_real_point
    end

    # Get source arrow.
    # @return [Wx::SF::ArrowBase]
    def get_src_arrow
      @src_arrow
    end
    alias :src_arrow :get_src_arrow

    # Set source arrow
    # @overload set_src_arrow(arrow)
    #   @param [Wx::SF::ArrowBase] arrow
    #   @return [Wx::SF::ArrowBase,nil] the new source arrow object if invalid
    # @overload set_src_arrow(arrow_klass)
    #   @param [Class] arrow_klass
    #   @return [Wx::SF::ArrowBase,nil] the new source arrow object if invalid
    def set_src_arrow(arg)
      if (arg.is_a?(::Class) && arg < ArrowBase) || arg.is_a?(ArrowBase)
        @src_arrow = arg.is_a?(ArrowBase) ? arg : arg.new
        @src_arrow.set_parent_shape(self)
      end
      nil
    end
    alias :src_arrow= :set_src_arrow

    # Get target arrow.
    # @return [Wx::SF::ArrowBase]
    def get_trg_arrow
      @trg_arrow
    end
    alias :trg_arrow :get_trg_arrow

    # Set target arrow
    # @overload set_trg_arrow(arrow)
    #   @param [Wx::SF::ArrowBase] arrow
    #   @return [Wx::SF::ArrowBase,nil] the new source arrow object if invalid
    # @overload set_trg_arrow(arrow_klass)
    #   @param [Class] arrow_klass
    #   @return [Wx::SF::ArrowBase,nil] the new source arrow object if invalid
    def set_trg_arrow(arg)
      if (arg.is_a?(::Class) && arg < ArrowBase) || arg.is_a?(ArrowBase)
        @trg_arrow = arg.is_a?(ArrowBase) ? arg : arg.new
        @trg_arrow.set_parent_shape(self)
      end
      nil
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

            if trg_bb.contains?(src_center.x.to_i, src_center.y.to_i)
              if src_center.y > trg_center.y
                src = Wx::RealPoint.new(src_center.x, src_bb.bottom.to_f)
                trg = Wx::RealPoint.new(src_center.x, trg_bb.bottom.to_f)
              else
                src = Wx::RealPoint.new(src_center.x, src_bb.top.to_f)
                trg = Wx::RealPoint.new(src_center.x, trg_bb.top.to_f)
              end
              return [src, trg]
            elsif src_bb.contains?(trg_center.x.to_i, trg_center.y.to_i)
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

    # Get number of line segments for this shape.
    # @return [Integer] number of line segments
    def get_line_segment_count
      @lst_points.size+1
    end
    alias :line_segment_count :get_line_segment_count
    alias :segment_count :get_line_segment_count

    # Get starting and ending point of line segment defined by its index.
	  # @param [Integer] index Index of desired line segment
	  # @return [Array(Wx::RealPoint,Wx::RealPoint)] starting and ending point of line segment
    def get_line_segment(index)
      if @lst_points.empty?
        return get_direct_line if index == 0
      else
        if index == 0
          return [get_src_point, @lst_points.first.dup]
        elsif index == @lst_points.size
          return [@lst_points.last.dup, get_trg_point]
        elsif index > 0 && index < @lst_points.size
          return @lst_points[index-1, 2].collect {|p| p.dup}
        end
      end
      [Wx::RealPoint.new, Wx::RealPoint.new]
    end
    
	  # Get line's bounding box. The function can be overridden if necessary.
    # @return [Wx::Rect] Bounding rectangle
    def get_bounding_box
      line_rct = nil
    
      # calculate control points area if they exist
      if !@lst_points.empty?
        prev_pt = get_src_point.to_point
    
        @lst_points.each do |pt|
          pt = pt.to_point
          if line_rct.nil?
            line_rct = Wx::Rect.new(prev_pt, pt)
          else
            line_rct.union!(Wx::Rect.new(prev_pt, pt))
          end
          prev_pt = pt
        end
    
        line_rct.union!(Wx::Rect.new(prev_pt, get_trg_point.to_point))
      else
        # include starting point
        pt = get_src_point
        line_rct = Wx::Rect.new(pt.x.to_i, pt.y.to_i, 1, 1)

        # include ending point
        pt = get_trg_point
        line_rct.union!(Wx::Rect.new(pt.x.to_i, pt.y.to_i, 1, 1))
      end
    
      # include unfinished point if the line is under construction
      if @mode == LINEMODE::UNDERCONSTRUCTION || @mode == LINEMODE::SRCCHANGE || @mode == LINEMODE::TRGCHANGE
        if line_rct.nil?
          line_rct = Wx::Rect.new(@unfinished_point.x, @unfinished_point.y, 1, 1)
        else
          line_rct.union!(Wx::Rect.new(@unfinished_point.x, @unfinished_point.y, 1, 1))
        end
      end
    
      line_rct ? line_rct : Wx::Rect.new
    end

	  # Get the shape's absolute position in the canvas.
	  # @return [Wx::RealPoint] Shape's position
    def get_absolute_position
      get_dock_point_position(@dock_point)
    end

	  # Get intersection point of the shape border and a line leading from
	  # 'start_pt' point to 'end_pt' point. The function can be overridden if necessary.
	  # @param [Wx::RealPoint] _start_pt Starting point of the virtual intersection line
    # @param [Wx::RealPoint] _end_pt Ending point of the virtual intersection line
	  # @return [Wx::RealPoint] Intersection point
    def get_border_point(_start_pt, _end_pt)
      get_absolute_position
    end

	  # Test whether the given point is inside the shape. The function
    # can be overridden if necessary.
    # @param pos Examined point
    # @return TRUE if the point is inside the shape area, otherwise FALSE
    def contains?(pos)
      return true if @mode != LINEMODE::UNDERCONSTRUCTION && get_hit_linesegment(pos) >= 0
      false
    end

	  # Move the shape to the given absolute position. The function
    # can be overridden if necessary.
	  # @param [Float] x X coordinate
	  # @param [Float] y Y coordinate
    def move_to(x, y)
      move_by(x - @prev_position.x, y - @prev_position.y)
      @prev_position.x = x
      @prev_position.y = y
    end

	  # Move the shape by the given offset. The function
    #  can be overridden if necessary.
	  # @param [Float] x X offset
	  # @param [Float] y Y offset
    def move_by(x, y)
      @lst_points.each do |pt|
        pt.x += x
        pt.y += y
      end

      if @stand_alone
        @src_point += [x, y]
        @trg_point += [x, y]
      end

      update unless @child_shapes.empty?

      get_diagram.set_modified if get_diagram
    end

	  # Function called by the framework responsible for creation of shape handles
    # at the creation time. The function can be overridden if necessary.
    def create_handles
      # first clear all previously used handles and then create new ones
      @handles.clear
    
      # create control points handles
      @lst_points.size.times { |i| add_handle(Shape::Handle::TYPE::LINECTRL, i) }
    
      # create border handles
      add_handle(Shape::Handle::TYPE::LINESTART)
      add_handle(Shape::Handle::TYPE::LINEEND)
    end

	  # Event handler called during dragging of the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # @param [Wx::SF::Shape::Handle] handle Reference to dragged handle
    def on_handle(handle)
      case handle.type
      when Shape::Handle::TYPE::LINECTRL
        pt = @lst_points[handle.id]
        if pt
          pt.x = handle.get_position.x
          pt.y = handle.get_position.y
        end

      when Shape::Handle::TYPE::LINEEND
        @unfinished_point = handle.get_position
        @trg_point = handle.get_position.to_real if @stand_alone

      when Shape::Handle::TYPE::LINESTART
        @unfinished_point = handle.get_position
        @src_point = handle.get_position.to_real if @stand_alone
      end
    
      super
    end

	  # Event handler called when the user finished dragging of the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # Default implementation does nothing.
    # @param [Wx::SF::Shape::Handle] handle Reference to dragged handle
    def on_end_handle(handle)
      # update percentual offset of the line's ending points
      parent = get_parent_canvas.get_shape_under_cursor
    
      if parent && !@stand_alone
        bb_rect = parent.get_bounding_box
    
        case handle.type
        when Shape::Handle::TYPE::LINESTART
          if parent.id == @src_shape_id
            @src_offset.x = (handle.get_position.x - bb_rect.left).to_f / bb_rect.width
            @src_offset.y = (handle.get_position.y - bb_rect.top).to_f / bb_rect.height
          end

        when Shape::Handle::TYPE::LINEEND
          if parent.id == @trg_shape_id
            @trg_offset.x = (handle.get_position.x - bb_rect.left).to_f / bb_rect.width
            @trg_offset.y = (handle.get_position.y - bb_rect.top).to_f / bb_rect.height
          end
        end
      end
    
      super
    end

	  # Event handler called at the beginning of the shape dragging process.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
    # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_begin_drag(pos)
      @prev_position = get_absolute_position

      super
    end

	  # Event handler called when the shape is double-clicked by
	  # the left mouse button. The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
    # @param [Wx::Point] pos Current mouse position
	  # @see Wx::SF::ShapeCanvas
    def on_left_double_click(pos)
      # HINT: override it for custom actions
    
      if get_parent_canvas
        # remove existing handle if exist otherwise create a new one at the
        # given position
        handle = get_parent_canvas.get_topmost_handle_at_position(pos)
        if handle && handle.get_parent_shape == self
          if handle.type == Shape::Handle::TYPE::LINECTRL
            if has_style?(STYLE::EMIT_EVENTS)
              evt = Wx::SF::ShapeHandleEvent.new(EVT_SF_LINE_HANDLE_REMOVE, id)
              evt.set_shape(self)
              evt.set_handle(handle)
              get_parent_canvas.get_event_handler.process_event(evt)
            end
    
            @lst_points.delete_at(handle.id)
    
            create_handles
            show_handles(true)
          end
        else
          index = get_hit_linesegment(pos)
          if index > -1
            @lst_points.insert(index, Wx::RealPoint.new(pos.x, pos.y))
    
            create_handles
            show_handles(true)
    
            if has_style?(STYLE::EMIT_EVENTS)
              handle = get_parent_canvas.get_topmost_handle_at_position(pos)
              if handle
                evt = ShapeHandleEvent.new(EVT_SF_LINE_HANDLE_ADD, id)
                evt.set_shape(this)
                evt.set_handle(handle)
                get_parent_canvas.get_event_handler.process_event(evt)
              end
            end
          end
        end
      end
    end

	  # Scale the shape size by in both directions. The function can be overridden if necessary
    # (new implementation should call default one or scale shape's children manually if necessary).
    # @param [Float] x Horizontal scale factor
    # @param [Float] y Vertical scale factor
    # @param [Boolean] children true if the shape's children should be scaled as well, otherwise the shape will be updated after scaling via update() function.
    def scale(x, y, children = WITHCHILDREN)
      @lst_points.each do |pt|
        pt.x *= x
        pt.y *= y
      end
    
      # call default function implementation (needed for scaling of shape's children)
      super
    end

    # Get current working mode.
    # @return [LINEMODE] Current working mode
    # @see LINEMODE
    def get_line_mode
      @mode
    end

    protected

	  # Draw the shape in the normal way. The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)
      dc.with_pen(@pen) do
        draw_complete_line(dc)
      end
    end

	  # Draw the shape in the hower mode (the mouse cursor is above the shape).
    # The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)
      dc.with_pen(Wx::Pen.new(@hover_color, 1)) do
        draw_complete_line(dc)
      end
    end

	  # Draw the shape in the highlighted mode (another shape is dragged over this
    # shape and this shape will accept the dragged one if it will be dropped on it).
    # The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_highlighted(dc)
      dc.with_pen(Wx::Pen.new(@hover_color, 2)) do
        draw_complete_line(dc)
      end
    end

    # Draw completed line.
    # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_complete_line(dc)
      return unless diagram
    
      case @mode
      when LINEMODE::READY
        # draw basic line parts
        src = trg = nil
        line_segment_count.times do |i|
          src, trg = get_line_segment(i)
          dc.draw_line(src.to_point, trg.to_point)
        end
        # draw target arrow
        @trg_arrow.draw(src, trg, dc) if @trg_arrow
        # draw source arrow
        if @src_arrow
          src, trg = get_line_segment(0)
          @src_arrow.draw(trg, src, dc)
        end

      when LINEMODE::UNDERCONSTRUCTION
        # draw basic line parts
        src = trg = nil
        @lst_points.size.times do |i|
          src, trg = get_line_segment(i)
          dc.draw_line(src.to_point, trg.to_point)
        end
        # draw unfinished line segment if any (for interactive line creation)
        dc.with_pen(Wx::Pen.new(Wx::BLACK, 1, Wx::PENSTYLE_DOT)) do
          if @lst_points.size > 0
            dc.draw_line(trg, @unfinished_point)
          else
            src_shape = diagram.find_shape(@src_shape_id)
            if src_shape
              if src_shape.get_connection_points.empty?
                dc.draw_line((src_shape.get_border_point(src_shape.get_center, @unfinished_point.to_real)).to_point,
                             @unfinished_point)
              else
                dc.draw_line(get_mod_src_point.to_point, @unfinished_point)
              end
            end
          end
        end

      when LINEMODE::SRCCHANGE
        # draw basic line parts
        src = trg = nil
        @lst_points.size.times do |i|
          src, trg = get_line_segment(i+1)
          dc.draw_line(src.to_point, trg.to_point)
        end

        # draw linesegment being updated
        src, trg = get_line_segment(0)

        dc.set_pen(Wx::Pen.new(Wx::BLACK, 1, Wx::PENSTYLE_DOT)) unless @stand_alone
        dc.draw_line(@unfinished_point, trg.to_point)
        dc.set_pen(Wx::NULL_PEN) unless @stand_alone

      when LINEMODE::TRGCHANGE
        # draw basic line parts
        src = trg = nil
        if @lst_points.empty?
          trg = get_src_point
        else
          @lst_points.size.times do |i|
            src, trg = get_line_segment(i)
            dc.draw_line(src.to_point, trg.to_point)
          end
        end
        # draw linesegment being updated
        dc.set_pen(Wx::Pen.new(Wx::BLACK, 1, Wx::PENSTYLE_DOT)) unless @stand_alone
        dc.draw_line(trg.to_point, @unfinished_point)
        dc.set_pen(Wx::NULL_PEN) unless @stand_alone
      end
    end

    # Get index of the line segment intersecting the given point.
	  # @param [Wx::Point] pos Examined point
	  # @return [Integer] Zero-based index of line segment located under the given point
    def get_hit_linesegment(pos)
      return -1 unless get_bounding_box.contains?(pos)

      pos = pos.to_point
      # Get all polyline segments
      line_segment_count.times do |i|
        src, trg = get_line_segment(i)

        # calculate line segment bounding box
        ls_bb = Wx::Rect.new(src.to_point, trg.to_point)
        ls_bb.inflate!(2)
    
        # convert line segment to its parametric form
        a = trg.y - src.y
        b = src.x - trg.x
        c = -a*src.x - b*src.y
    
        # calculate distance of the line and give point
        d = (a*pos.x + b*pos.y + c)/::Math.sqrt(a*a + b*b)
        # NaN will be the result if src and trg are equal
        # (which can happen for lines between parent and child shapes)
        return i if (d.nan? || d.to_i.abs <= 5) && ls_bb.contains?(pos)
      end
    
      -1
    end

    # Set line shape's working mode.
    # @param [LINEMODE] mode Working mode
    # @see LINEMODE
    def set_line_mode(mode)
      @mode = mode
    end

    # Set next potential control point position (useful in LINEMODE::UNDERCONSTRUCTION working mode).
	  # @param [Wx::Point] pos New potential control point position
    # @see LINEMODE
    def set_unfinished_point(pos)
      @unfinished_point = pos.to_point
    end

    # Get modified starting line point .
	  # @return [Wx::RealPoint] Modified starting line point
    def get_mod_src_point
      src_shape = diagram.find_shape(@src_shape_id)
      return Wx::RealPoint.new unless src_shape
    
      if @src_offset != DEFAULT::OFFSET
        bb_rct = src_shape.get_bounding_box
        mod_point = src_shape.get_absolute_position
    
        mod_point.x += bb_rct.width.to_f * @src_offset.x
        mod_point.y += bb_rct.height.to_f * @src_offset.y
      else
        mod_point = src_shape.get_center
      end
    
      conn_pt = src_shape.get_nearest_connection_point(mod_point)
      mod_point = conn_pt.get_connection_point if conn_pt
    
      mod_point
    end

    # Get modified ending line point .
	  # @return [Wx::RealPoint] Modified ending line point
    def get_mod_trg_point
      trg_shape = diagram.find_shape(@trg_shape_id)
      return Wx::RealPoint.new unless trg_shape

      if @trg_offset != DEFAULT::OFFSET
        bb_rct = trg_shape.get_bounding_box
        mod_point = trg_shape.get_absolute_position

        mod_point.x += bb_rct.width.to_f * @trg_offset.x
        mod_point.y += bb_rct.height.to_f * @trg_offset.y
      else
        mod_point = trg_shape.get_center
      end

      conn_pt = trg_shape.get_nearest_connection_point(mod_point)
      mod_point = conn_pt.get_connection_point if conn_pt

      mod_point
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
      @src_offset = offs.to_real_point
    end

    # Serialization only
    # @return [Wx::RealPoint]
    def get_trg_offset
      @trg_offset
    end

    # Deserialization only
    # @param [Wx::RealPoint] offs
    def set_trg_offset(offs)
      @trg_offset = offs.to_real_point
    end

    # (De-)Serialization only
    def serialize_src_point(*arg)
      @src_point = arg.shift unless arg.empty?
      @src_point
    end

    # (De-)Serialization only
    def serialize_trg_point(*arg)
      @trg_point = arg.shift unless arg.empty?
      @trg_point
    end

  end

end
