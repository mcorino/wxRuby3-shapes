# Wx::SF - Sample2
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes'
require_relative 'sample_shape'
require_relative 'sample_canvas'

class SFSample2Frame < Wx::Frame

  class LOGTYPE < Wx::Enum
    MouseEvent = self.new(1002)
    HandleEvent = self.new(1003)
    KeyEvent = self.new(1004)
    ChildDropEvent = self.new(1005)
  end

  class << self
    def log(logtype, msg)
      main_frame = Wx.get_app.get_top_window

      if main_frame.log_menu.is_checked(logtype.to_i)
        main_frame.text_log.append_text(msg)
      end
    end
  end

  module ID
    MenuQuit = 1000
    MenuAbout = 1001
    MenuLogMouseEvent = 1002
    MenuLogHandleEvent = 1003
    MenuLogKeyEvent = 1004
    MenuLogChildDropEvent = 1005
  end

  def initialize(title)
    super(nil, Wx::StandardID::ID_ANY, title, size: [800,600])

    self.icon = Wx::Icon(:sample)

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
    @diagram.accept_shape(SampleShape)

    # create shape canvas and associate it with shape manager
    @canvas = SampleCanvas.new(@diagram, self)

    main_sizer.add(@canvas, 1, Wx::EXPAND, 0)

    @text_log = Wx::TextCtrl.new(self, size: [-1, 150], style: Wx::TE_MULTILINE)
    @text_log.set_font(Wx::Font.new(8, Wx::FONTFAMILY_SWISS, Wx::FONTSTYLE_NORMAL, Wx::FONTWEIGHT_NORMAL, false, 'Sans'))
    @text_log.set_min_size(Wx::Size.new(-1, 150))

    main_sizer.add(@text_log, 0, Wx::EXPAND, 0)

    if Wx.has_feature?(:USE_STATUSBAR)
      # create a status bar with some information about the used wxWidgets version
      create_status_bar(2)
      set_status_text('Hello wxRuby ShapeFramework user!',0)
      set_status_text("wxRuby #{Wx::WXRUBY_VERSION} #{Wx::PLATFORM} (wxWidgets #{Wx::WXWIDGETS_VERSION})", 1)
    end # wxUSE_STATUSBAR

    set_sizer(main_sizer)
    layout
    center
  end

  attr_reader :log_menu, :text_log

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
    msg += "wxRuby SF event handlers are overridden in user-defined canvas and shape class.\n\n"
    msg += "Usage:\n"
    msg += " - Left mouse click operates with inserted shapes\n"
    msg += " - Right mouse click inserts a rectangular shape to the canvas\n"
    msg += " - DEL key removes selected shape\n"

    Wx.message_box(msg, "wxRuby ShapeFramework Sample 2")
  end

end

Wx::App.run do
  SFSample2Frame.new('wxShapeFramework Sample 1').show
end
