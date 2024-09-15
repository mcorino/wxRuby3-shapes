# Wx::SF event classes
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  # Class encapsulates generic Wx::SF shape's event.
  class ShapeEvent < Wx::Event
    # Constructor
    # @param [Integer] evt_type
    # @param [FIRM::Serializable::ID, Integer] id
    def initialize(evt_type = Wx::EVT_NULL, id = 0)
      super(evt_type, id.to_i)
      @shape = nil
      @vetoed = false
    end

    # Insert a shape object to the event object.
    # @param [Wx::SF::Shape] shape shape object
    def set_shape(shape)
      @shape = shape
    end
    alias :shape= :set_shape

    # Get a shape object from the event object.
    # @return [Wx::SF::Shape,nil] shape object.
    def get_shape
      @shape
    end
    alias :shape :get_shape

    # Check if the event has been vetoed or not.
    # @return [Boolean] true if the event has been vetoed.
    def is_vetoed
      @vetoed
    end
    alias :vetoed? :is_vetoed

    # Set the veto flag to true.
    def veto
      @vetoed = true
    end
  end

  # Class encapsulates Wx::SF shape's key down event.
  class ShapeKeyEvent < Wx::Event
    # Constructor
    # @param [Integer] evt_type
    # @param [FIRM::Serializable::ID, Integer] id
    def initialize(evt_type = Wx::EVT_NULL, id = 0)
      super(evt_type, id.to_i)
      @shape = nil
      @key_code = 0
    end

    # Insert a shape object to the event object.
    # @param [Wx::SF::Shape] shape shape object
    def set_shape(shape)
      @shape = shape
    end
    alias :shape= :set_shape

    # Get a shape object from the event object.
    # @return [Wx::SF::Shape,nil] shape object.
    def get_shape
      @shape
    end
    alias :shape :get_shape

    # Set key code.
    # @param [Integer] key_code Code of pressed key
    def set_key_code(key_code)
      @key_code = key_code
    end
    alias :key_code= :set_key_code

    # Get key code.
    # @return Code of pressed key
    def get_key_code
      @key_code
    end
    alias :key_code :get_key_code
  end

  # Class encapsulates Wx::SF shape's mouse event.
  class ShapeMouseEvent < Wx::Event
    # Constructor
    # @param [Integer] evt_type
    # @param [FIRM::Serializable::ID, Integer] id
    def initialize(evt_type = Wx::EVT_NULL, id = 0)
      super(evt_type, id.to_i)
      @shape = nil
      @mouse_pos = Wx::DEFAULT_POSITION
    end

    # Insert a shape object to the event object.
    # @param [Wx::SF::Shape] shape shape object
    def set_shape(shape)
      @shape = shape
    end
    alias :shape= :set_shape

    # Get a shape object from the event object.
    # @return [Wx::SF::Shape,nil] shape object.
    def get_shape
      @shape
    end
    alias :shape :get_shape

    # Set absolute position of mouse cursor.
    # @param [Wx::Point] mouse_position Mouse cursor's absolute position
    def set_mouse_position(mouse_position)
      @mouse_position = mouse_position.to_point
    end
    alias :mouse_position= :set_mouse_position

    # Get absolute position of mouse cursor
    # @return [Wx::Point] Mouse cursor's absolute position
    def get_mouse_position
      @mouse_position
    end
    alias :mouse_position :get_mouse_position
  end

  # Class encapsulates Wx::SF shape text change event.
  class ShapeTextEvent < Wx::Event
    # Constructor
    # @param [Integer] evt_type
    # @param [FIRM::Serializable::ID, Integer] id
    def initialize(evt_type = Wx::EVT_NULL, id = 0)
      super(evt_type, id.to_i)
      @shape = nil
      @text = ''
    end

    # Insert a shape object to the event object.
    # @param [Wx::SF::Shape] shape shape object
    def set_shape(shape)
      @shape = shape
    end
    alias :shape= :set_shape

    # Get a shape object from the event object.
    # @return [Wx::SF::Shape,nil] shape object.
    def get_shape
      @shape
    end
    alias :shape :get_shape

    # Set new shape text
    # @param [String] text new text
    def set_text(text)
      @text = text
    end
    alias :text= :set_text

    # Get shape text
    # @return [String] shape text
    def get_text
      @text
    end
    alias :text :get_text
  end

  # Class encapsulates Wx::SF shape handle related event.
  class ShapeHandleEvent < Wx::Event
    # Constructor
    # @param [Integer] evt_type
    # @param [FIRM::Serializable::ID, Integer] id
    def initialize(evt_type = Wx::EVT_NULL, id = 0)
      super(evt_type, id.to_i)
      @shape = nil
      @handle = nil
    end

    # Insert a shape object to the event object.
    # @param [Wx::SF::Shape] shape shape object
    def set_shape(shape)
      @shape = shape
    end
    alias :shape= :set_shape

    # Get a shape object from the event object.
    # @return [Wx::SF::Shape,nil] shape object.
    def get_shape
      @shape
    end
    alias :shape :get_shape

    # Set dragged shape handle
    # @param [Wx::Shape::Handle] handle shape handle
    def set_handle(handle)
      @handle = handle
    end
    alias :handle= :set_handle

    # Get shape handle
    # @return [Wx::SF::Shape::Handle] shape handle
    def get_handle
      @handle
    end
    alias :handle :get_handle
  end

  if Wx.has_feature?(:USE_DRAG_AND_DROP)

  # Class encapsulates Wx::SF shape on drop event.
  class ShapeDropEvent < Wx::Event
    # Constructor
    # @param [Integer] evt_type
    # @param [Integer] x
    # @param [Integer] y
    # @param [Wx::SF::ShapeCanvas] target
    # @param [Wx::DragResult] def_result
    # @param [FIRM::Serializable::ID, Integer] id
    def initialize(evt_type = Wx::EVT_NULL, x = 0, y = 0, target = nil, def_result = Wx::DragResult::DragNone, id = 0)
      super(evt_type, id.to_i)
      @dropped_shapes = []
      @drop_position = Wx::Point.new(x, y)
      @drop_target = target
      @drag_result = def_result
    end

    # Add given shapes to dropped shapes list.
    # @param [Array<Wx::SF::Shape>] shapes shape list
    def set_dropped_shapes(shapes)
      @dropped_shapes.concat(shapes)
    end
    alias :dropped_shapes= :set_dropped_shapes

    # Get list of dropped shapes
    # @return [Array<Wx::SF::Shape>] shape list
    def get_dropped_shapes
      @dropped_shapes
    end
    alias :dropped_shapes :get_dropped_shapes

    # Set position where shapes were dropped
    # @param [Wx::Point] pos drop position
    def set_drop_position(pos)
      @drop_position = pos.to_point
    end
    alias :drop_position= :set_drop_position

    # Get drop position
    # @return [Wx::Point] drop position
    def get_drop_position
      @drop_position
    end
    alias :drop_position :get_drop_position

    # Set target (shape canvas) where shapes were dropped
    # @param [Wx::SF::ShapeCanvas] trg drop target
    def set_drop_target(trg)
      @drop_target = trg
    end
    alias :drop_target= :set_drop_target

    # Get drop target
    # @return [Wx::SF::ShapeCanvas] drop target
    def get_drop_target
      @drop_target
    end
    alias :drop_target :get_drop_target

    # Set drag result
    # @param [Wx::DragResult] dr drag result
    def set_drag_result(dr)
      @drag_result = dr
    end
    alias :drag_result= :set_drag_result

    # Get drag result
    # @return [Wx::DragResult] drag result
    def get_drag_result
      @drag_result
    end
    alias :drag_result :get_drag_result
  end

  end

  # Class encapsulates Wx::SF shape paste event.
  class ShapePasteEvent < Wx::Event
    # Constructor
    # @param [Integer] evt_type
    # @param [Wx::SF::ShapeCanvas] target
    # @param [FIRM::Serializable::ID, Integer] id
    def initialize(evt_type = Wx::EVT_NULL, target = nil, id = 0)
      super(evt_type, id.to_i)
      @pasted_shapes = []
      @drop_target = target
    end

    # Add given shapes to pasted shapes list.
    # @param [Array<Wx::SF::Shape>] shapes shape list
    def set_pasted_shapes(shapes)
      @pasted_shapes.concat(shapes)
    end
    alias :pasted_shapes= :set_pasted_shapes

    # Get list of pasted shapes
    # @return [Array<Wx::SF::Shape>] shape list
    def get_pasted_shapes
      @pasted_shapes
    end
    alias :pasted_shapes :get_pasted_shapes

    # Set target (shape canvas) where shapes are pasted
    # @param [Wx::SF::ShapeCanvas] trg drop target
    def set_drop_target(trg)
      @drop_target = trg
    end
    alias :drop_target= :set_drop_target

    # Get drop target
    # @return [Wx::SF::ShapeCanvas] drop target
    def get_drop_target
      @drop_target
    end
    alias :drop_target :get_drop_target
  end

  # Class encapsulates Wx::SF shape child drop event.
  class ShapeChildDropEvent < Wx::Event
    # Constructor
    # @param [Integer] evt_type
    # @param [FIRM::Serializable::ID, Integer] id
    def initialize(evt_type = Wx::EVT_NULL, id = 0)
      super(evt_type, id.to_i)
      @shape = nil
      @child = nil
    end

    # Insert a shape object to the event object.
    # @param [Wx::SF::Shape] shape shape object
    def set_shape(shape)
      @shape = shape
    end
    alias :shape= :set_shape

    # Get a shape object from the event object.
    # @return [Wx::SF::Shape,nil] shape object.
    def get_shape
      @shape
    end
    alias :shape :get_shape

    # Set dropped child shape
    # @param [Wx::SF::Shape] child child shape object
    def set_child_shape(child)
      @child = child
    end
    alias :child_shape= :set_child_shape

    # Get child shape object from the event object.
    # @return [Wx::SF::Shape,nil] child shape object.
    def get_child_shape
      @child
    end
    alias :child_shape :get_child_shape
  end

  EVT_SF_LINE_DONE = Wx::EvtHandler.register_class(ShapeEvent, nil, 'evt_sf_line_done', 0)
  EVT_SF_TEXT_CHANGE = Wx::EvtHandler.register_class(ShapeTextEvent, nil, 'evt_sf_text_change', 0)
  if Wx.has_feature?(:USE_DRAG_AND_DROP)
  EVT_SF_ON_DROP = Wx::EvtHandler.register_class(ShapeDropEvent, nil, 'evt_sf_on_drop', 0)
  end
  EVT_SF_ON_PASTE = Wx::EvtHandler.register_class(ShapePasteEvent, nil, 'evt_sf_on_paste', 0)
  EVT_SF_SHAPE_LEFT_DOWN = Wx::EvtHandler.register_class(ShapeMouseEvent, nil, 'evt_sf_shape_left_down', 0)
  EVT_SF_SHAPE_LEFT_DCLICK = Wx::EvtHandler.register_class(ShapeMouseEvent, nil, 'evt_sf_shape_left_dclick', 0)
  EVT_SF_SHAPE_RIGHT_DOWN = Wx::EvtHandler.register_class(ShapeMouseEvent, nil, 'evt_sf_shape_right_down', 0)
  EVT_SF_SHAPE_RIGHT_DCLICK = Wx::EvtHandler.register_class(ShapeMouseEvent, nil, 'evt_sf_shape_right_dclick', 0)
  EVT_SF_SHAPE_DRAG_BEGIN = Wx::EvtHandler.register_class(ShapeMouseEvent, nil, 'evt_sf_shape_drag_begin', 0)
  EVT_SF_SHAPE_DRAG = Wx::EvtHandler.register_class(ShapeMouseEvent, nil, 'evt_sf_shape_drag', 0)
  EVT_SF_SHAPE_DRAG_END = Wx::EvtHandler.register_class(ShapeMouseEvent, nil, 'evt_sf_shape_drag_end', 0)
  EVT_SF_SHAPE_HANDLE_BEGIN = Wx::EvtHandler.register_class(ShapeHandleEvent, nil, 'evt_sf_shape_handle_begin', 0)
  EVT_SF_SHAPE_HANDLE = Wx::EvtHandler.register_class(ShapeHandleEvent, nil, 'evt_sf_shape_handle', 0)
  EVT_SF_SHAPE_HANDLE_END = Wx::EvtHandler.register_class(ShapeHandleEvent, nil, 'evt_sf_shape_handle_end', 0)
  EVT_SF_SHAPE_KEYDOWN = Wx::EvtHandler.register_class(ShapeKeyEvent, nil, 'evt_sf_shape_keydown', 0)
  EVT_SF_SHAPE_MOUSE_ENTER = Wx::EvtHandler.register_class(ShapeMouseEvent, nil, 'evt_sf_shape_mouse_enter', 0)
  EVT_SF_SHAPE_MOUSE_OVER = Wx::EvtHandler.register_class(ShapeMouseEvent, nil, 'evt_sf_shape_mouse_over', 0)
  EVT_SF_SHAPE_MOUSE_LEAVE = Wx::EvtHandler.register_class(ShapeMouseEvent, nil, 'evt_sf_shape_mouse_leave', 0)
  EVT_SF_SHAPE_CHILD_DROP = Wx::EvtHandler.register_class(ShapeChildDropEvent, nil, 'evt_sf_shape_child_drop', 0)
  EVT_SF_LINE_BEFORE_DONE = Wx::EvtHandler.register_class(ShapeEvent, nil, 'evt_sf_line_before_done', 0)
  EVT_SF_LINE_HANDLE_ADD = Wx::EvtHandler.register_class(ShapeHandleEvent, nil, 'evt_sf_line_handle_add', 0)
  EVT_SF_LINE_HANDLE_REMOVE = Wx::EvtHandler.register_class(ShapeHandleEvent, nil, 'evt_sf_line_handle_remove', 0)
  EVT_SF_SHAPE_SIZE_CHANGED = Wx::EvtHandler.register_class(ShapeEvent, nil, 'evt_sf_shape_size_changed', 0)
  
end
