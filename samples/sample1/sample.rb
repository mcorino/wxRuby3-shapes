# Wx::SF - Sample1
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes'

class SFSample1Frame < Wx::Frame

  module ID
    MenuQuit = 1000
    MenuAbout = 1001
    MenuLogMouseEvent = 1002
    MenuLogHandleEvent = 1003
    MenuLogKeyEvent = 1004
    MenuLogChildDropEvent = 1005
  end

  def initialize(title)
    super(nil, Wx::StandardID::ID_ANY, title)
    
    set_size([800, 600])

    # initialize event types
    @event_type_info = {
      Wx::SF::EVT_SF_SHAPE_LEFT_DOWN => "Shape was clicked by LMB (wxEVT_SF_SHAPE_LEFT_DOWN )",
      Wx::SF::EVT_SF_SHAPE_LEFT_DCLICK => "Shape was double-clicked by LMB (wxEVT_SF_SHAPE_LEFT_DOWN )",
      Wx::SF::EVT_SF_SHAPE_RIGHT_DOWN => "Shape was clicked by RMB (wxEVT_SF_SHAPE_RIGHT_DOWN )",
      Wx::SF::EVT_SF_SHAPE_RIGHT_DCLICK => "Shape was double-clicked by RMB (wxEVT_SF_SHAPE_RIGHT_DOWN )",
      Wx::SF::EVT_SF_SHAPE_DRAG_BEGIN => "Shape has started to be dragged (wxEVT_SF_SHAPE_DRAG_BEGIN )",
      Wx::SF::EVT_SF_SHAPE_DRAG => "Shape is dragging (wxEVT_SF_SHAPE_DRAG )",
      Wx::SF::EVT_SF_SHAPE_DRAG_END => "Shape's dragging was finished (wxEVT_SF_SHAPE_DRAG_END )",
      Wx::SF::EVT_SF_SHAPE_HANDLE_BEGIN => "Shape handle has started to be dragged (wxEVT_SF_SHAPE_HANDLE_BEGIN )",
      Wx::SF::EVT_SF_SHAPE_HANDLE => "Shape handle is dragging (wxEVT_SF_SHAPE_HANDLE )",
      Wx::SF::EVT_SF_SHAPE_HANDLE_END => "Shape handle's dragging was finished (wxEVT_SF_SHAPE_HANDLE_END )",
      Wx::SF::EVT_SF_SHAPE_KEYDOWN => "Key was pressed (wxEVT_SF_SHAPE_KEYDOWN )",
      Wx::SF::EVT_SF_SHAPE_MOUSE_ENTER => "Mouse has entered shape's area (wxEVT_SF_SHAPE_MOUSE_ENTER)",
      Wx::SF::EVT_SF_SHAPE_MOUSE_OVER => "Mouse is moving over shape's area (wxEVT_SF_SHAPE_MOUSE_OVER)",
      Wx::SF::EVT_SF_SHAPE_MOUSE_LEAVE => "Mouse has leaved shape's area (wxEVT_SF_SHAPE_MOUSE_LEAVE)",
      Wx::SF::EVT_SF_SHAPE_CHILD_DROP => "Child shape has been assigned to shape (wxEVT_SF_SHAPE_CHILD_DROP)",
      Wx::SF::EVT_SF_LINE_HANDLE_ADD => "Line handle has been created (wxEVT_SF_LINE_HANDLE_ADD)",
      Wx::SF::EVT_SF_LINE_HANDLE_REMOVE => "Line handle has been removed (wxEVT_SF_LINE_HANDLE_REMOVE)"
    }

    evt_close :on_close

    if Wx.has_feature?(:USE_MENUS)
      # create a menu bar
      mbar = Wx::MenuBar.new
      file_menu = Wx::Menu.new
      file_menu.append(ID::MenuQuit, "&Quit\tAlt-F4", "Quit the application")
      mbar.append(file_menu, "&File")
  
      @log_menu = Wx::Menu.new
      @log_menu.append_check_item(ID::MenuLogMouseEvent, "Log &mouse events")
      @log_menu.append_check_item(ID::MenuLogHandleEvent, "Log &handle events")
      @log_menu.append_check_item(ID::MenuLogKeyEvent, "Log &keyboard events")
      @log_menu.append_check_item(ID::MenuLogChildDropEvent, "Log &child drop event")
      mbar.append(@log_menu, "&Log")
  
      help_menu = Wx::Menu.new
      help_menu.append(ID::MenuAbout, "&About\tF1", "Show info about this application")
      mbar.append(help_menu, "&Help")
  
      self.menu_bar = mbar

      evt_menu(ID::MenuQuit, :on_quit)
      evt_menu(ID::MenuAbout, :on_about)
    end # wxUSE_MENUS

    main_sizer = Wx::FlexGridSizer.new(2, 0, 0, 0)
    main_sizer.add_growable_col(0)
    main_sizer.add_growable_row(0)
    main_sizer.set_flexible_direction(Wx::Orientation::BOTH)
    main_sizer.set_non_flexible_grow_mode(Wx::FlexSizerGrowMode::FLEX_GROWMODE_SPECIFIED)

    @diagram = Wx::SF::Diagram.new
    # set some diagram manager properties if necessary...
    # set accepted shapes (accept only Wx::SF::RectShape)
    @diagram.clear_accepted_shapes
    @diagram.accept_shape(Wx::SF::RectShape)
    @diagram.accept_shape('Wx::SF::CurveShape')
    
    # create shape canvas and associate it with shape manager
    @canvas = Wx::SF::ShapeCanvas.new(@diagram, self)
    # set some shape canvas properties if necessary...
	  @canvas.add_style(Wx::SF::ShapeCanvas::STYLE::GRID_SHOW)
    @canvas.add_style(Wx::SF::ShapeCanvas::STYLE::GRID_USE)

    # connect (some) shape canvas events
    @canvas.evt_left_down { |evt| self.on_left_click_canvas(evt) }
    @canvas.evt_right_down { |evt| self.on_right_click_canvas(evt) }

    # connect (some) shape events (for full list of available shape/shape canvas events see Wx::SF reference documentation).
    @canvas.evt_sf_shape_left_down { |evt| self.on_shape_mouse_event(evt) }
    @canvas.evt_sf_shape_left_dclick { |evt| self.on_shape_mouse_event(evt) }
    @canvas.evt_sf_shape_right_down { |evt| self.on_shape_mouse_event(evt) }
    @canvas.evt_sf_shape_right_dclick { |evt| self.on_shape_mouse_event(evt) }
    @canvas.evt_sf_shape_drag_begin { |evt| self.on_shape_mouse_event(evt) }
    @canvas.evt_sf_shape_drag { |evt| self.on_shape_mouse_event(evt) }
    @canvas.evt_sf_shape_drag_end { |evt| self.on_shape_mouse_event(evt) }
  
    @canvas.evt_sf_shape_mouse_enter { |evt| self.on_shape_mouse_enter_event(evt) }
    @canvas.evt_sf_shape_mouse_over { |evt| self.on_shape_mouse_event(evt) }
    @canvas.evt_sf_shape_mouse_leave { |evt| self.on_shape_mouse_event(evt) }
  
    @canvas.evt_sf_shape_handle_begin { |evt| self.on_shape_handle_event(evt) }
    @canvas.evt_sf_shape_handle { |evt| self.on_shape_handle_event(evt) }
    @canvas.evt_sf_shape_handle_end { |evt| self.on_shape_handle_event(evt) }
    @canvas.evt_sf_line_handle_add { |evt| self.on_shape_handle_event(evt) }
    @canvas.evt_sf_line_handle_remove { |evt| self.on_shape_handle_event(evt) }
  
    @canvas.evt_sf_shape_keydown { |evt| self.on_shape_key_event(evt) }
  
    @canvas.evt_sf_shape_child_drop { |evt| self.on_shape_child_drop_event(evt) }
  
    @canvas.evt_sf_line_done { |evt| self.on_line_finished(evt) }

    main_sizer.add(@canvas, 1, Wx::EXPAND, 0)

    @text_log = Wx::TextCtrl.new(self, size: [-1, 150], style: Wx::TE_MULTILINE)
    @text_log.set_font(Wx::Font.new(8, Wx::FONTFAMILY_SWISS, Wx::FONTSTYLE_NORMAL, Wx::FONTWEIGHT_NORMAL, false, 'Sans'))
    @text_log.set_min_size(Wx::Size.new(-1, 150))

    main_sizer.add(@text_log, 0, Wx::EXPAND, 0)

    set_sizer(main_sizer)
    layout

    if Wx.has_feature?(:USE_STATUSBAR)
      # create a status bar with some information about the used wxWidgets version
      create_status_bar(2)
      set_status_text('Hello wxRuby ShapeFramework user!',0)
      set_status_text(Wx::PLATFORM, 1)
    end # wxUSE_STATUSBAR

    set_sizer(main_sizer)
    layout
    center
  end

  # Window event handlers

  def on_close(_event)
    destroy
  end

  def on_quit(_event)
    destroy
  end

  def on_about(_event)
    msg = "wxRuby ShapeFramework #{Wx::SF::VERSION}\n(wxRuby #{Wx::WXRUBY_VERSION} #{Wx::PLATFORM}; #{Wx::WXWIDGETS_VERSION})\n\n"

    msg += "Welcome to wxRuby ShapeFramework Sample1 (c) Martin Corino, 2023\n"
    msg += "(ported from wxSFShapeFramework original (c) Michal Bliznak, 2007 - 2013)\n\n"
    msg += "Sample demonstrates basic Wx::SF functionality.\n"
    msg += "Usage:\n"
    msg += " - Left mouse click operates with inserted shapes\n"
    msg += " - Right mouse click inserts a rectangular shape to the canvas\n"
    msg += " - Right mouse click onto the shape + CTRL key starts interactive line connection \n"
    msg += " - DEL key removes selected shape\n"

    Wx.message_box(msg, "wxRuby ShapeFramework Sample 1")
  end

  # event handlers for shape canvas

  def on_left_click_canvas(event)
    # HINT: perform your user actions here...

    # ... and then process standard canvas operations
    event.skip
  end

  def on_right_click_canvas(event)
    if event.control_down
      # create connection line
      @canvas.start_interactive_connection(Wx::SF::CurveShape, event.get_position)
    else
      # add new rectangular shape to the diagram ...
      _err, shape = @diagram.create_shape(Wx::SF::RectShape, event.get_position)
      # set some shape's properties...
      if shape
        # set accepted child shapes for the new shape
        shape.accept_child('Wx::SF::RectShape')
        # set accepted connections for the new shape
        shape.accept_connection('*')
        shape.accept_src_neighbour('Wx::SF::RectShape')
        shape.accept_trg_neighbour('Wx::SF::RectShape')
        # enable emitting of shape events
        shape.add_style(Wx::SF::Shape::STYLE::EMIT_EVENTS)
      end
    end
    # ... and process standard canvas operations
    event.skip
  end

  # event handlers for shapes

  def on_shape_mouse_enter_event(event)
    # if @log_menu.is_checked(ID::MenuLogMouseEvent)
      @text_log.append_text("#{@event_type_info[event.get_event_type]}, ID: #{event.get_id}, Mouse position: #{event.get_mouse_position.x},#{event.get_mouse_position.y}\n")
    # end
  end

  def on_shape_mouse_event(event)
    if @log_menu.is_checked(ID::MenuLogMouseEvent)
      @text_log.append_text("#{@event_type_info[event.get_event_type]}, ID: #{event.get_id}, Mouse position: #{event.get_mouse_position.x},#{event.get_mouse_position.y}\n")
    end
  end

  def on_shape_handle_event(event)
    if @log_menu.is_checked(ID::MenuLogHandleEvent)
      hnd_type =case event.handle.type
                when Wx::SF::Shape::Handle::LEFTTOP
                  "left-top"
                when Wx::SF::Shape::Handle::TOP
                  "top"
                when Wx::SF::Shape::Handle::RIGHTTOP
                  "right-top"
                when Wx::SF::Shape::Handle::LEFT
                  "left"
                when Wx::SF::Shape::Handle::RIGHT
                  "right"
                when Wx::SF::Shape::Handle::LEFTBOTTOM
                  "left-bottom"
                when Wx::SF::Shape::Handle::BOTTOM
                  "bottom"
                when Wx::SF::Shape::Handle::RIGHTBOTTOM
                  "right-bottom"
                when Wx::SF::Shape::Handle::LINECTRL
                  "line-control"
                else
                  ''
                end
  
      @text_log.append_text("%s, Shape ID: %d, Handle type: %d (%s), Delta: %d,%d\n" % [
                                    @event_type_info[event.get_event_type],
                                    event.get_id,
                                    event.get_handle.get_type,
                                    hnd_type,
                                    event.get_handle.get_delta.x,
                                    event.get_handle.get_delta.y])
    end
  end

  def on_shape_key_event(event)
    if @log_menu.is_checked(ID::MenuLogKeyEvent)
      @text_log.append_text("%s, Shape ID: %d, Key code: %d\n" % [
                                    @event_type_info[event.get_event_type],
                                    event.get_id,
                                    event.get_key_code])
    end
  end

  def on_shape_child_drop_event(event)
    if @log_menu.is_checked(ID::MenuLogChildDropEvent)
      @text_log.append_text("%s, Shape ID: %d, Child ID: %d\n" % [
                                    @event_type_info[event.get_event_type],
                                    event.get_id,
                                    event.get_child_shape.get_id])
    end
  end

  def on_line_finished(event)
    event.get_shape.add_style(Wx::SF::Shape::STYLE::EMIT_EVENTS) if event.get_shape
  end

end

Wx::App.run do
  SFSample1Frame.new('wxShapeFramework Sample 1').show
end
