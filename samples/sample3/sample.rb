# Wx::SF - Sample3
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes'

class StarShape < Wx::SF::PolygonShape

  # star shape vertices
  STAR = [Wx::RealPoint.new(0, -50), Wx::RealPoint.new(15, -10),
          Wx::RealPoint.new(50, -10), Wx::RealPoint.new(22, 10),
          Wx::RealPoint.new(40, 50), Wx::RealPoint.new(0, 20),
          Wx::RealPoint.new(-40, 50), Wx::RealPoint.new(-22, 10),
          Wx::RealPoint.new(-50, -10), Wx::RealPoint.new(-15, -10)]

  # regular property
  property :description
  # component shape property (this specifies that this item should be serialized as a property of this class and
  # not from any reference elsewhere like it's parents child shapes list)
  component :title
  # disable serialization of polygon vertices for this PolygonShape derivative,
  # because they are always set in constructor for this class
  excludes :vertices

  # @overload initialize()
  #   Default constructor.
  # @overload initialize(pos, size, diagram)
  #   User constructor.
  #   @param [Wx::RealPoint] pos Initial position
  #   @param [Wx::SF::Diagram] diagram parent diagram
  def initialize(*args)
    if args.empty?
      super()
      set_vertices(STAR)
    else
      pos, diagram = args
      super(STAR, pos, diagram)
    end
    init
  end

  protected

  def get_description
    @description
  end

  def set_description(desc)
    @description = desc
  end

  def get_title
    @text
  end

  private

  def set_title(txt)
    @text = txt
  end

  def init
    # initialize custom data members...
    @description = "Insert some shape's description text here..."

    # polygon-based shapes can be connected either to the vertices or to the
    # nearest border point (default value is true).
    set_connect_to_vertex(false)

    # set accepted connections for the new shape
    accept_connection(Wx::SF::ACCEPT_ALL)
    accept_src_neighbour(StarShape)
    accept_trg_neighbour(StarShape)

    # create associated shape(s)
    @text = Wx::SF::EditTextShape.new
    # set some properties
    if @text
      # set text
      @text.set_text('Hello!')
      # set alignment
      @text.set_v_align(Wx::SF::Shape::VALIGN::MIDDLE)
      @text.set_h_align(Wx::SF::Shape::HALIGN::CENTER)

      # set required shape style(s)
      @text.set_style(STYLE::ALWAYS_INSIDE | STYLE::HOVERING | STYLE::PROCESS_DEL | STYLE::PROPAGATE_DRAGGING | STYLE::PROPAGATE_SELECTION | STYLE::PROPAGATE_INTERACTIVE_CONNECTION)
      # you can also force displaying of the shapes handles even if the interactive
      # size change is not allowed:
      #@text.add_style(STYLE::SHOW_HANDLES)

      # we use #set_parent_shape and not #add_child_shape as we do not want it checked against the acceptance list
      # (which is empty and we want to keep it like  that) and we already know it's not yet on the diagram so does
      # not need to be removed as toplevel shape
      @text.set_parent_shape(self)
      # component will/should be added as child shape but will not be serialized as such
      # instead the 'component :title' declaration above makes sure it will be serialized
      # as a dedicated property of instances of this class

    end
  end

end

class SFSample3Frame < Wx::Frame

  module ID
    MenuQuit = 1000
    MenuOpen = 1001
    MenuSave = 1002
    MenuAbout = 1003
  end

  def initialize(title)
    super(nil, Wx::StandardID::ID_ANY, title, size: [800,600])

    self.icon = Wx::Icon(:sample)

    if Wx.has_feature?(:USE_MENUS)
      # create a menu bar
      mbar = Wx::MenuBar.new
      file_menu = Wx::Menu.new
      file_menu.append(ID::MenuOpen, "&Open\tCtrl-O", 'Open diagram from XML file')
      file_menu.append(ID::MenuSave, "&Save\tCtrl-S", 'Save diagram to XML file')
      file_menu.append_separator
      file_menu.append(ID::MenuQuit, "&Quit\tAlt-F4", "Quit the application")
      mbar.append(file_menu, "&File")

      help_menu = Wx::Menu.new
      help_menu.append(ID::MenuAbout, "&About\tF1", "Show info about this application")
      mbar.append(help_menu, "&Help")
  
      self.menu_bar = mbar

      evt_menu(ID::MenuOpen, :on_open)
      evt_menu(ID::MenuSave, :on_save)
      evt_menu(ID::MenuQuit, :on_quit)
      evt_menu(ID::MenuAbout, :on_about)
    end # wxUSE_MENUS
    @diagram = Wx::SF::Diagram.new
    # set some diagram manager properties if necessary...
    # set accepted shapes (accept only Wx::SF::RectShape)
    @diagram.clear_accepted_shapes
    @diagram.accept_shape(StarShape)
    @diagram.accept_shape(Wx::SF::TextShape)
    @diagram.accept_shape(Wx::SF::LineShape)

    # create shape canvas and associate it with shape manager
    @canvas = Wx::SF::ShapeCanvas.new(@diagram, self)
    # set some shape canvas properties if necessary...
	  @canvas.add_style(Wx::SF::ShapeCanvas::STYLE::GRID_SHOW)
    @canvas.add_style(Wx::SF::ShapeCanvas::STYLE::GRID_USE)

    evt_close :on_close

    # connect (some) shape canvas events
    @canvas.evt_left_down { |evt| self.on_left_click_canvas(evt) }
    @canvas.evt_right_down { |evt| self.on_right_click_canvas(evt) }

    # connect (some) shape events (for full list of available shape/shape canvas events see Wx::SF reference documentation).
    @canvas.evt_sf_line_done { |evt| self.on_line_done(evt) }
    @canvas.evt_sf_text_change { |evt| self.on_text_change(evt) }

    if Wx.has_feature?(:USE_STATUSBAR)
      # create a status bar with some information about the used wxWidgets version
      create_status_bar(2)
      set_status_text('Hello wxRuby ShapeFramework user!',0)
      set_status_text("wxRuby #{Wx::WXRUBY_VERSION} #{Wx::PLATFORM} (wxWidgets #{Wx::WXWIDGETS_VERSION})", 1)
    end # wxUSE_STATUSBAR

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

    msg += "Welcome to wxRuby ShapeFramework Sample3 (c) Martin Corino, 2023\n"
    msg += "(ported from wxSFShapeFramework original (c) Michal Bliznak, 2007 - 2013)\n\n"
    msg += "Sample demonstrates basic Wx::SF functionality.\n"
    msg += " - New custom 'composite' shape is created.\n"
    msg += " - Shapes can be joined together by lines.\n\n"
    msg += "Usage:\n"
    msg += " - Left mouse click operates with inserted shapes\n"
    msg += " - Right mouse click inserts a custom shape to the canvas or starts\n"
    msg += "   interactive connection line's creation process\n"
    msg += " - You can modify the star's text (double click it by the left mouse button)\n"
    msg += " - DEL key removes selected shape\n"

    Wx.message_box(msg, "wxRuby ShapeFramework Sample 3")
  end

  # event handlers for shape canvas

  def on_left_click_canvas(event)
    # HINT: perform your user actions here...

    # ... and then process standard canvas operations
    event.skip
  end

  def on_right_click_canvas(event)
    # find out whether some shape has been clicked
    if @canvas.get_shape_at_position(@canvas.dp2lp(event.get_position))
      # start interactive connection creation
      @canvas.start_interactive_connection(Wx::SF::LineShape, event.get_position)
    else
      # create new composite shape
      @diagram.add_shape(s = StarShape.new, nil, event.get_position, Wx::SF::INITIALIZE, Wx::SF::DONT_SAVE_STATE)

      # ... and process standard canvas operations
      event.skip
    end
  end

  # event handlers for shapes

  # Event handler called when the interactive line creation process is finished.
  # Alternatively you can override virtual function Wx::SF::ShapeCanvas#on_connection_finished.
  def on_line_done(event)
    # get new line shape (if created)
    line = event.get_shape

    if line.is_a?(Wx::SF::LineShape)
      # assign target arrow to the line shape (also source arrow can be created)
      line.set_trg_arrow(Wx::SF::SolidArrow)
    end
  end

  # Event handler called when a text inside the star was changed.
  # Alternatively you can override virtual function Wx::SF::ShapeCanvas#on_text_change.
  def on_text_change(event)
    # get changed text shape
    text = event.get_shape
	
    if text.is_a?(Wx::SF::TextShape)
		  # update the text shape and its parent(s)
      text.update
		  # display some info...
      Wx.log_message("New text of the star with ID #{text.get_parent_shape.id.to_i} is : '#{event.text}'")
    end
  end

  def on_open(_event)
    Wx::FileDialog(self, 'Load diagram from file...', Dir.getwd, '', "JSON Files (*.json)|*.json", Wx::FD_OPEN) do |dlg|
      if dlg.show_modal == Wx::ID_OK
        File.open(dlg.get_path, 'r') do |f|
          @canvas.set_diagram(FIRM::Serializable.deserialize(f))
          @canvas.clear_canvas_history
          @canvas.save_canvas_state
        end
        @diagram = @canvas.get_diagram
        @canvas.refresh(false)
      end
    end
  end

  def on_save(_event)
    Wx::FileDialog(self, 'Save diagram to XML...', Dir.getwd, '', 'JSON Files (*.json)|*.json', Wx::FD_SAVE) do |dlg|
      if dlg.show_modal == Wx::ID_OK
        # save diagram to file
        File.open(dlg.get_path, 'w+') do |f|
          @diagram.serialize(f, pretty: true)
        end
        Wx.message_box("The diagram has been saved to '#{dlg.get_path}'.", 'wxRuby ShapeFramework')
      end
    end
  end

end

Wx::App.run do
  SFSample3Frame.new('wxShapeFramework Sample 3').show
end
