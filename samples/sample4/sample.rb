# Wx::SF - Sample4
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes'


class TestPanel < Wx::Panel

  ID_RESIZE = Wx::ID_HIGHEST+1

  def initialize(parent)
    super(parent, size: [150, 100])
    @big = false
    btn_resize = Wx::Button.new(self, ID_RESIZE, 'Resize me!!!', [10, 10])

    evt_button ID_RESIZE, :on_btn_resize

    set_background_colour(Wx::Colour.new(100, 100, 200))
  end

  protected

  def on_btn_resize(event)
    if !@big
      set_client_size(get_client_size + Wx::Size.new(50, 50))
    else
      set_client_size(get_client_size - Wx::Size.new(50, 50))
    end

    @big = !@big
  end
end

class SFSample4Frame < Wx::Frame

  module ID
    MenuQuit = 1000
    MenuAbout = 1001
  end

  def initialize(title)
    super(nil, Wx::StandardID::ID_ANY, title, size: [800,600])

    self.icon = Wx::Icon(:sample)

    if Wx.has_feature?(:USE_MENUS)
      # create a menu bar
      mbar = Wx::MenuBar.new
      file_menu = Wx::Menu.new
      file_menu.append(ID::MenuQuit, "&Quit\tAlt-F4", "Quit the application")
      mbar.append(file_menu, "&File")

      help_menu = Wx::Menu.new
      help_menu.append(ID::MenuAbout, "&About\tF1", "Show info about this application")
      mbar.append(help_menu, "&Help")
  
      self.menu_bar = mbar

      evt_menu(ID::MenuQuit, :on_quit)
      evt_menu(ID::MenuAbout, :on_about)
    end # wxUSE_MENUS

    @control_type = 0

    @diagram = Wx::SF::Diagram.new
    # set some diagram manager properties if necessary...
    # set accepted shapes (accept only Wx::SF::RectShape)
    @diagram.clear_accepted_shapes
    @diagram.accept_shape(Wx::SF::ControlShape)

    # create shape canvas and associate it with shape manager
    @canvas = Wx::SF::ShapeCanvas.new(@diagram, self)
    @canvas.set_scrollbars(20,20,50,50)
    # set some shape canvas properties if necessary...
    @canvas.add_style(Wx::SF::ShapeCanvas::STYLE::GRID_USE)

    evt_close :on_close

    # connect (some) shape canvas events
    @canvas.evt_left_down { |evt| self.on_left_click_canvas(evt) }
    @canvas.evt_right_down { |evt| self.on_right_click_canvas(evt) }

    if Wx.has_feature?(:USE_STATUSBAR)
      # create a status bar with some information about the used wxWidgets version
      create_status_bar(2)
      set_status_text('Hello wxRuby ShapeFramework user!',0)
      set_status_text("wxRuby #{Wx::WXRUBY_VERSION} #{Wx::PLATFORM} (wxWidgets #{Wx::WXWIDGETS_VERSION})", 1)
    end # wxUSE_STATUSBAR

    center
  end

  def create_gui_control
    @control_type = (@control_type + 1 ) % 5
  
    case @control_type
    when 0
      Wx::Button.new(@canvas, label: 'Hello World!', size: [100, 50])
    when 1
      Wx::TextCtrl.new(@canvas, value: 'Hello World!', size: [150, 100], style: Wx::TE_MULTILINE)
    when 2
      Wx::Slider.new(@canvas, value: 50, min_value: 0, max_value: 100, size: [150, -1])
    when 3
      ctrl = Wx::Gauge.new(@canvas, range: 50, size: [100, -1])
      ctrl.set_value(25)
      ctrl
    when 4
      TestPanel.new(@canvas)
    else
      nil
    end
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

    msg += "Welcome to wxRuby ShapeFramework Sample3 (c) Martin Corino, 2023\n"
    msg += "(ported from wxSFShapeFramework original (c) Michal Bliznak, 2007 - 2013)\n\n"
    msg += "Sample demonstrates possibility to manage GUI controls (widgets) by the wxSFControlShape.\n"
    msg += "Usage:\n"
    msg += " - Left mouse click operates with inserted GUI controls\n"
    msg += " - Right mouse click inserts a GUI control to the canvas\n"
    msg += " - DEL key removes selected shape\n"

    Wx.message_box(msg, "wxRuby ShapeFramework Sample 4")
  end

  # event handlers for shape canvas

  def on_left_click_canvas(event)
    # HINT: perform your user actions here...

    # ... and then process standard canvas operations
    event.skip
  end

  def on_right_click_canvas(event)
    # add new rectangular shape to the diagram ...
    _, shape = @diagram.create_shape(Wx::SF::ControlShape, event.get_position)
    # set some shape's properties...
    if shape
      # set accepted child shapes for the new shape
      shape.clear_accepted_childs

      # Some visual aspects can be set here:
      shape.set_control_offset(5)
      #shape.set_mod_border(Wx::TRANSPARENT_PEN)
      #shape.set_mod_fill(Wx::Brush(Wx::RED, Wx::CROSSDIAG_HATCH))

      # Assign managed GUI control to the canvas. Remember the control shape now owns the GUI control and it is
      # deleted by the shape control in its destructor. If you want to remove the GUI control from the parent shape
      # just assign a new control or nil value to it. You can also specify whether managed GUI control
      # is resized in accordance to dimensions of its parent control shape or vice versa.
      shape.set_control(create_gui_control, Wx::SF::FIT_SHAPE_TO_CONTROL)

      # You can specify whether events generated by the managed control are processed by the shape canvas
      # or/and the widget as well. Note that GUI controls differ in a way how they process events
      # so the behaviour can be different for various widgets.
      shape.set_event_processing(Wx::SF::ControlShape::EVTPROCESSING::MOUSE2CANVAS | Wx::SF::ControlShape::EVTPROCESSING::KEY2CANVAS)
      #shape.set_event_processing(Wx::SF::ControlShape::EVTPROCESSING::MOUSE2GUI | Wx::SF::ControlShape::EVTPROCESSING::KEY2GUI)
    end

    # ... and process standard canvas operations
    event.skip
  end

end

Wx::App.run do
  SFSample4Frame.new('wxShapeFramework Sample 4').show
end
