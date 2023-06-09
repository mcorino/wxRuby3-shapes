# Wx::SF::TextShape - control shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'

module Wx::SF

  FIT_SHAPE_TO_CONTROL = true
  FIT_CONTROL_TO_SHAPE = false

  # Class encapsulates a special shape able to manage assigned GUI controls (widgets). The GUI control's
  # position and size can by modified via parent control shape. User can also specify how events incoming from the
  # managed GUI control are processed.
  #
  # Note that the managed controls use a shape canvas as their parent window so these shapes cannot be used
  # without existing and properly initialized shape canvas. Moreover, managed GUI controls are not serialized in any
  # way internally so it is completely up to the user to provide this functionality if needed.
  class ControlShape < RectShape

    # Auxiliary class used by Wx::SF::ControlShape. All events generated by a GUI control (widget)
    # managed by parent control shape are redirected to this event sink which invokes a default event handler
    # or send a copy of the event to shape canvas if requested.
    class EventSink < Wx::EvtHandler

      # @overload initialize()
      #   Default constructor.
      # @overload initialize(parent)
      #   User constructor.
      #   @param [ControlShape] parent parent control shape
      def initialize(parent = nil)
        @parent_shape = parent
      end
      
      # Event handler used for delayed processing of a mouse button events.
      # The handler creates new key event instance and sends it to a shape canvas for further processing.
	    # @param [Wx::MouseEvent] event Mouse event
      def _on_mouse_button(event)
        if (@parent_shape.get_event_processing & EVTPROCESSING::MOUSE2CANVAS) != 0
            updated_event = event.clone

            update_mouse_event(updated_event)
            send_event(updated_event)
        end

        # process the event also by an original handler if requested
        event.skip if (@parent_shape.get_event_processing & EVTPROCESSING::MOUSE2GUI) != 0

        # @parent_shape.get_control.set_focus
      end

      # Event handler used for delayed processing of a mouse event (mouse movement).
      # The handler creates new key event instance and sends it to a shape canvas for further processing.
      # @param [Wx::MouseEvent] event Mouse event
      def _on_mouse_move(event)
        if (@parent_shape.get_event_processing & EVTPROCESSING::MOUSE2CANVAS) != 0
          updated_event = event.clone

          update_mouse_event(updated_event)
          send_event(updated_event)
        end

        # process the event also by an original handler if requested
        event.skip if (@parent_shape.get_event_processing & EVTPROCESSING::MOUSE2GUI) != 0
      end

      # Event handler used for delayed processing of a key event.
      # The handler creates new key event instance and sends it to a shape canvas for further processing.
	    # @param [Wx::KeyEvent] event Keyboard event
      def _on_key_down(event)
        send_event(event) if (@parent_shape.get_event_processing & EVTPROCESSING::KEY2CANVAS) !=0

        # process the event also by an original handler if requested
        event.skip if (@parent_shape.get_event_processing & EVTPROCESSING::KEY2GUI) != 0
      end

      # Event handler used for adjusting the parent shape's size in accordance to size of managed GUI control.
      # @param [Wx::SizeEvent] event Size event
      def _on_size(event)
        event.skip

        @parent_shape.update_shape
      end

      protected

      # Send copy of incoming event to a shape canvas.
      # @param [Wx::Event] event Event to be send
      def send_event(event)
        if @parent_shape && @parent_shape.get_diagram
            canvas = @parent_shape.get_diagram.get_shape_canvas
            # send copy of the event to the shape canvas
            Wx.post_event(canvas, event) if canvas
        end
      end

      # Modify given mouse event (recalculate the event's position in accordance to parent control
      # shape's position.
      # @param [Wx::MouseEvent] event Mouse event to be updated
      def update_mouse_event(event)
        abs_pos = @parent_shape.get_absolute_position

        x, y = @parent_shape.get_parent_canvas.calc_unscrolled_position(0, 0)

        event.x += (abs_pos.x.to_i + @parent_shape.get_control_offset - x)
        event.y += (abs_pos.y.to_i + @parent_shape.get_control_offset - y)
      end

    end

    # Way of processing of GUI control's events.
    class EVTPROCESSING < Wx::Enum
        # Event isn't processed.
        NONE = self.new(0)
        # Keyboard events are processed by the GUI control.
        KEY2GUI = self.new(1)
        # Keyboard events are send to a shape canvas. 
        KEY2CANVAS = self.new(2)
        # Mouse events are processed by the GUI control. 
        MOUSE2GUI = self.new(4)
        # Mouse events are send to a shape canvas. 
        MOUSE2CANVAS = self.new(8)
    end

    # Defaults
    module DEFAULT
      CONTROLOFFSET = 0
      PROCESSEVENTS = EVTPROCESSING::KEY2CANVAS | EVTPROCESSING::MOUSE2CANVAS
      MODFILL = Wx::Brush.new(Wx::BLUE, Wx::BrushStyle::BRUSHSTYLE_BDIAGONAL_HATCH) if Wx::App.is_main_loop_running
      Wx.add_delayed_constant(self, :MODFILL) { Wx::Brush.new(Wx::BLUE, Wx::BrushStyle::BRUSHSTYLE_BDIAGONAL_HATCH) }
      MODBORDER = Wx::Pen.new(Wx::BLUE, 1, Wx::PenStyle::PENSTYLE_SOLID) if Wx::App.is_main_loop_running
      Wx.add_delayed_constant(self, :MODBORDER) { Wx::Pen.new(Wx::BLUE, 1, Wx::PenStyle::PENSTYLE_SOLID) }
    end

    property :event_processing, :control_offset, :mod_fill, :mod_border

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, diagram)
    #   User constructor.
    #   @param [Wx::Window] ctrl managed GUI control
    #   @param [Wx::Point] pos Initial position
    #   @param [Wx::Size] size Initial size
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)
      if args.empty?
        super
        @control = nil
      else
        ctrl = args.shift
        super(*args)
        set_control(ctrl)
      end
      add_style(Shape::STYLE::PROCESS_DEL)
      @process_events = DEFAULT::PROCESSEVENTS
      @mod_fill = DEFAULT::MODFILL
      @mod_border = DEFAULT::MODBORDER
      @control_offset = DEFAULT::CONTROLOFFSET

      @event_sink = EventSink.new(self)

      @prev_parent = nil
      @prev_style = 0
      @prev_fill = nil
      @prev_border = nil

      @fill = Wx::TRANSPARENT_BRUSH
      @border = Wx::TRANSPARENT_PEN
    end

    # Set managed GUI control.
    # @param [Wx::Window] ctrl existing manager GUI control
    # @param [Boolean] fit true if the control shape should be resized in accordance to the given GUI control
    def set_control(ctrl, fit = FIT_SHAPE_TO_CONTROL)
      if @control
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_LEFT_DOWN)
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_RIGHT_DOWN)
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_LEFT_UP)
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_RIGHT_UP)
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_LEFT_DCLICK)
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_RIGHT_DCLICK)
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_MOTION)
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_KEY_DOWN)
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_SIZE)
        @control.hide
        @control.reparent(@prev_parent)
      end

      @control = ctrl
  
      if @control
        @prev_parent = ctrl.get_parent
        if @diagram
          canvas = @diagram.get_shape_canvas

          # reparent GUI control if necessary
          @control.reparent(canvas) if canvas && canvas != @prev_parent

          # redirect mouse events to the event sink for their delayed processing
          @control.evt_left_down { |evt| @event_sink._on_mouse_button(evt) }
          @control.evt_right_down { |evt| @event_sink._on_mouse_button(evt) }
          @control.evt_left_up { |evt| @event_sink._on_mouse_button(evt) }
          @control.evt_right_up { |evt| @event_sink._on_mouse_button(evt) }
          @control.evt_left_dclick { |evt| @event_sink._on_mouse_button(evt) }
          @control.evt_right_dclick { |evt| @event_sink._on_mouse_button(evt) }
          @control.evt_motion { |evt| @event_sink._on_mouse_move(evt) }
          @control.evt_key_down { |evt| @event_sink._on_key_down(evt) }
          @control.evt_size { |evt| @event_sink._on_size(evt) }
        end

        update_shape if fit

        update_control
      end
    end

    # Get managed GUI control.
    # @return [Wx::Window] the GUI control
    def get_control
      @control
    end

    # Set the way how GUI control's events are processed.
    # @param [EVTPROCESSING] mask Event processing
    # @see EVTPROCESSING
    def set_event_processing(mask)
      @process_events = mask
    end

    # Get the way how GUI control's events are processed.
    # @return [EVTPROCESSING] Combination of EVTPROCESSING flags
    # @see EVTPROCESSING
    def get_event_processing
      @process_events
    end

    # Set control shape's background style used during its modification.
    # @param [Wx::Brush] brush Reference to used brush
    def set_mod_fill(brush)
      @mod_fill = brush
    end

    # Get control shape's background style used during its modification.
    # @return [Wx::Brush] Used brush
    def get_mod_fill
      @mod_fill
    end

    # Set control shape's border style used during its modification.
    # @param [Wx::Pen] pen Reference to used pen
    def set_mod_border(pen)
      @mod_border = pen
    end

    # Get control shape's border style used during its modification.
    # @return [Wx::Pen] Used pen
    def get_mod_border
      @mod_border
    end

    # Set control shape's offset (a gap between the shape's border and managed GUI control).
    # @param [Integer] offset Offset size
    def set_control_offset(offset)
      @control_offset = offset
    end

    # Get control shape's offset (a gap between the shape's border and managed GUI control).
    # @return [Integer] Offset size
    def get_control_offset
      @control_offset
    end

    # Update size and position of the managed control according to the parent shape.
    def update_control
      if @control
        min_bb = @control.get_min_size
        rct_bb = get_bounding_box.deflate([@control_offset, @control_offset])

        if rct_bb.width < min_bb.width
          rct_bb.width = min_bb.width
          @rect_size.x = min_bb.width + 2*@control_offset
        end
        if rct_bb.height < min_bb.height
          rct_bb.height = min_bb.height
          @rect_size.y = min_bb.height + 2*@control_offset
        end

        x, y = get_parent_canvas.calc_unscrolled_position(0, 0)

        # set the control's dimensions and position according to the parent control shape
        @control.set_size([rct_bb.width, rct_bb.height])
        @control.move(rct_bb.left - x, rct_bb.top - y)
      end
    end

    # Update size of the shape position according to the managed control.
    def update_shape
      if @control
        ctrl_size = @control.size

        @rect_size.x = ctrl_size.x + 2*@control_offset
        @rect_size.y = ctrl_size.y + 2*@control_offset

        get_parent_canvas.refresh(false)
      end
    end

	  # Scale the shape size by in both directions. The function can be overridden if necessary
    # (new implementation should call default one ore scale shape's children manually if necessary).
    # @param [Float] x Horizontal scale factor
    # @param [Float] y Vertical scale factor
    # @param children true if the shape's children should be scaled as well, otherwise the shape will be updated after scaling via update() function.
    def scale(x, y, children = WITHCHILDREN)
      super
      update_control
    end

	  # Move the shape to the given absolute position. The function can be overridden if necessary.
	  # @param [Float] x X coordinate
	  # @param [Float] y Y coordinate
    def move_to(x, y)
      super
      update_control
    end
    
	  # Move the shape by the given offset. The function can be overridden if necessary.
	  # @param [Float] x X offset
	  # @param [Float] y Y offset
    def move_by(x, y)
      super
      update_control
    end
	
	  # Update shape (align all child shapes an resize it to fit them)
    def update
      super
      update_control
    end

    # Resize the shape to bound all child shapes. The function can be overridden if necessary.
    def fit_to_children
      bb_rct = get_bounding_box

      ctrl_rct = if @control
                   Wx::Rect.new(@control.position, @control.size)
                 else
                   bb_rct
                 end

      super

      update_shape if bb_rct.intersects(ctrl_rct) && !bb_rct.contains(ctrl_rct)
    end

	  # Event handler called at the beginning of the shape dragging process.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
    # @param [Wx::Point] pos Current mouse position
	  # @see ShapeCanvas
    def on_begin_drag(pos)
      @prev_fill = @fill
      @fill = @mod_fill
      canvas = get_parent_canvas
      if canvas
        @prev_style = canvas.get_style
        canvas.remove_style(ShapeCanvas::STYLE::DND)
      end
      if @control
        @control.hide
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_SIZE)
      end

      super
    end

	  # Event handler called at the end of the shape dragging process.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # @param [Wx::Point] pos Current mouse position
	  # @see ShapeCanvas
    def on_end_drag(pos)
      @fill = @prev_fill
      canvas = get_parent_canvas
      canvas.set_style(@prev_style) if canvas
      update_control
      if @control
        @control.evt_size { |evt| @event_sink._on_size(evt) }
        @control.show
        @control.set_focus
      end

      super
    end

	  # Event handler called when the user started to drag the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
	  # @param [Shape::Handle] handle Reference to dragged handle
    def on_begin_handle(handle)
      @prev_border = @border
      @border = @mod_border
      @prev_fill = @fill
      @fill = @mod_fill
  
      if @control
        @control.hide
        @control.disconnect(Wx::ID_ANY, Wx::ID_ANY, Wx::EVT_SIZE)
      end
    
      # call default handler
      super
    end

	  # Event handler called during dragging of the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
    # @param [Shape::Handle] handle Reference to dragged handle
    def on_handle(handle)
      super
      update_control
    end

	  # Event handler called when the user finished dragging of the shape handle.
	  # The function can be overridden if necessary.
	  #
	  # The function is called by the framework (by the shape canvas).
    # @param [Shape::Handle] handle Reference to dragged handle
    def on_end_handle(handle)
      @border = @prev_border
      @fill = @prev_fill
  
      if @control
        @control.show
        @control.set_focus
        @control.evt_size { |evt| @event_sink._on_size(evt) }
      end
    
      # call default handler
      super
    end

    private

    def _on_key(key)
      super
      if key == Wx::K_DELETE
        set_control(nil)
        if @diagram
          @diagram.remove_shape(self, false)
        end
      end
    end

  end

end
