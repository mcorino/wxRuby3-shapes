# Wx::SF - Demo ThumbFrame, MainFrame and App
# Copyright (c) M.J.N. Corino, The Netherlands

require 'nokogiri'
require 'wx/shapes'
require_relative './frame_canvas'

class ThumbFrame < Wx::Frame

  def initialize(parent, title: 'Thumbnail', size: Wx::Size.new( 200,150 ), style: Wx::CAPTION|Wx::FRAME_FLOAT_ON_PARENT|Wx::FRAME_TOOL_WINDOW|Wx::RESIZE_BORDER|Wx::TAB_TRAVERSAL)
    super

    set_size_hints(Wx::DEFAULT_SIZE)

    main_sizer = Wx::VBoxSizer.new

    @thumbnail = Wx::SF::Thumbnail.new(self)
    main_sizer.add(@thumbnail, 1, Wx::EXPAND, 0)

    set_sizer(main_sizer)
    layout
  end

  attr_reader :thumbnail

end

class MainFrame < Wx::Frame

  class MODE < Wx::Enum
		DESIGN = self.new(0)
		RECT = self.new(1)
		FIXEDRECT = self.new(2)
		ROUNDRECT = self.new(3)
		ELLIPSE = self.new(4)
		CIRCLE = self.new(5)
		DIAMOND = self.new(6)
		TEXT = self.new(7)
		EDITTEXT = self.new(8)
		BITMAP = self.new(9)
		LINE = self.new(10)
		CURVE = self.new(11)
		ORTHOLINE = self.new(12)
		ROUNDORTHOLINE = self.new(13)
		GRID = self.new(14)
		FLEXGRID = self.new(15)
		STANDALONELINE = self.new(16)
    VBOX = self.new(17)
    HBOX = self.new(18)
  end

  module ID
    include Wx::IDHelper

    # menu IDs
    #---------------------------------------------------------------#
    M_SAVEASBITMAP = self.next_id

    # tool IDs
    #---------------------------------------------------------------#
    T_FIRST_TOOLMARKER = self.next_id
    T_GRID = self.next_id
    T_SHADOW = self.next_id
    T_GC = self.next_id
    T_TOOL = self.next_id
    T_RECTSHP = self.next_id
    T_SQUARESHP = self.next_id
    T_RNDRECTSHP = self.next_id
    T_ELLIPSESHP = self.next_id
    T_CIRCLESHP = self.next_id
    T_DIAMONDSHP = self.next_id
    T_TEXTSHP = self.next_id
    T_EDITTEXTSHP = self.next_id
    T_BITMAPSHP = self.next_id
    T_GRIDSHP = self.next_id
    T_FLEXGRIDSHP = self.next_id
    T_VBOXSHP = self.next_id
    T_HBOXSHP = self.next_id
    T_LINESHP = self.next_id
    T_STANDALONELINESHP = self.next_id
    T_CURVESHP = self.next_id
    T_ORTHOSHP = self.next_id
    T_RNDORTHOSHP = self.next_id
    T_ALIGN_LEFT = self.next_id
    T_ALIGN_RIGHT = self.next_id
    T_ALIGN_TOP = self.next_id
    T_ALIGN_BOTTOM = self.next_id
    T_ALIGN_MIDDLE = self.next_id
    T_ALIGN_CENTER = self.next_id
  
    T_LAST_TOOLMARKER = self.next_id
    
    M_AUTOLAYOUT_FIRST = self.next_id
    M_AUTOLAYOUT_LAST = M_AUTOLAYOUT_FIRST + 100
  
    # other controls
    #---------------------------------------------------------------#
    T_COLORPICKER = self.next_id(M_AUTOLAYOUT_LAST) + 1
  end

  FILE_MASK = 'JSON files (*.json)|*.json|YAML files (*.yaml,*.yml)|*.yaml;*.yml|XML files (*.xml)|*.xml|All files (*.*)|*.*;*'

  class DiagramFileDialog < Wx::FileDialogCustomizeHook

    FORMATS = %w[json yaml xml]

    def initialize(dlg, compact: nil)
      super()
      @format = nil
      @compact = compact.nil? ? nil : !!compact
      @choice = nil
      @checkbox = nil
      @dialog = dlg
      @dialog.set_customize_hook(self)
    end

    attr_reader :format, :compact

    def add_custom_controls(customizer)
      customizer.add_static_text('Format:')
      @choice = customizer.add_choice(FORMATS)
      unless @compact.nil?
        @checkbox = customizer.add_check_box('Compact content')
        @checkbox.set_value(true)
      end
    end

    def update_custom_controls
      case File.extname(@dialog.get_path)
      when '.json' then @choice.set_selection(0)
      when '.yaml', '.yml' then @choice.set_selection(1)
      when '.xml' then @choice.set_selection(2)
      end
    end

    def transfer_data_from_custom_controls
      @format = case @choice.get_selection
                when Wx::NOT_FOUND then nil
                else
                  FORMATS[@choice.get_selection].to_sym
                end
      @compact = @checkbox.get_value if @checkbox
      @dialog = nil
    end
  end

  def initialize(parent, title: 'wxShapeFramework Demo Application', style: Wx::CLOSE_BOX|Wx::DEFAULT_FRAME_STYLE|Wx::RESIZE_BORDER|Wx::TAB_TRAVERSAL)
    super

    set_icon(Wx::Icon(:sample))

    setup_frame

    @file_menu.append(Wx::ID_NEW, "&New\tCtrl+N", "New chart", Wx::ITEM_NORMAL)
    @file_menu.append(Wx::ID_OPEN, "&Open\tCtrl+O", "Load a chart from file", Wx::ITEM_NORMAL)
    @file_menu.append(Wx::ID_SAVE, "&Save as...\tCtrl+Shift+S", "Save the chart to file", Wx::ITEM_NORMAL)
    @file_menu.append_separator
    @file_menu.append(ID::M_SAVEASBITMAP, "&Export to image...", "Export the chart to BMP file", Wx::ITEM_NORMAL)
    @file_menu.append_separator
    @file_menu.append(Wx::ID_PRINT, "&Print...\tCtrl+P", "Open print dialog", Wx::ITEM_NORMAL)
    @file_menu.append(Wx::ID_PREVIEW, "Print pre&view...\tAlt+P", "Open print preview window", Wx::ITEM_NORMAL)
    @file_menu.append(Wx::ID_PAGE_SETUP, "Pa&ge setup...", "Set print page properties", Wx::ITEM_NORMAL)
    @file_menu.append_separator
    @file_menu.append(Wx::ID_EXIT, "E&xit\tAlt+X", "Close application", Wx::ITEM_NORMAL)
  
    @edit_menu.append(Wx::ID_UNDO, "&Undo\tCtrl+Z", "Discard previous action", Wx::ITEM_NORMAL)
    @edit_menu.append(Wx::ID_REDO, "&Redo\tCtrl+Y", "Re-do previously discarded action", Wx::ITEM_NORMAL)
    @edit_menu.append_separator
    @edit_menu.append(Wx::ID_SELECTALL, "Select &all\tCtrl+A", "Select all shapes", Wx::ITEM_NORMAL)
    @edit_menu.append_separator
    @edit_menu.append(Wx::ID_COPY, "&Copy\tCtrl+C", "Copy shapes to the clipboard", Wx::ITEM_NORMAL)
    @edit_menu.append(Wx::ID_CUT, "Cu&t\tCtrl+X", "Cut shapes to the clipboard", Wx::ITEM_NORMAL)
    @edit_menu.append(Wx::ID_PASTE, "&Paste\tCtrl+V", "Paste shapes to the canvas", Wx::ITEM_NORMAL)

    Wx::SF::AutoLayout.layout_algorithms.each_with_index do |la_name, i|
      @auto_layout_menu.append(ID::M_AUTOLAYOUT_FIRST + i, la_name)
    end
  
    @help_menu.append(Wx::ID_ABOUT, '&About...', 'About application...', Wx::ITEM_NORMAL)

    # set shape canvas and associate it with diagram
    @diagram = Wx::SF::Diagram.new
    @shape_canvas = FrameCanvas.new(@diagram, @canvas_panel, Wx::ID_ANY)
    @canvas_sizer.add(@shape_canvas, 1, Wx::EXPAND, 0)
    @canvas_panel.layout
    # enable using Wx::GraphicsContext by default
    # (effective only if wxUSE_GRAPHICS_CONTEXT if set to 1 for wxRuby)
    Wx::SF::ShapeCanvas::enable_gc
    
    # create and show canvas thumbnail
    @thumb_frm = ThumbFrame.new(self)
    @thumb_frm.thumbnail.set_canvas(@shape_canvas)
    @thumb_frm.show
  
    # create colour picker
    if Wx::PLATFORM == 'WXMSW'
      @cpicker = Wx::ColourPickerCtrl.new(@tool_bar, ID::T_COLORPICKER, Wx::Colour.new(120, 120, 255), Wx::DEFAULT_POSITION, Wx::Size.new(22, 22))
    else
      @cpicker = Wx::ColourPickerCtrl.new(@tool_bar, ID::T_COLORPICKER, Wx::Colour.new(120, 120, 255), Wx::DEFAULT_POSITION, Wx::Size.new(28, 28))
    end
    @cpicker.set_tool_tip('Set hover color')
    
  	# add m_pToolBar tools
    @tool_bar.set_tool_bitmap_size([16, 15])
    @tool_bar.add_tool(Wx::ID_NEW, 'New', Wx::ArtProvider.get_bitmap(Wx::ART_NEW, Wx::ART_MENU), 'New diagram')
    @tool_bar.add_tool(Wx::ID_OPEN, 'Load', Wx::ArtProvider.get_bitmap(Wx::ART_FILE_OPEN, Wx::ART_MENU), 'Open file...')
    @tool_bar.add_tool(Wx::ID_SAVE, 'Save', Wx::ArtProvider.get_bitmap(Wx::ART_FILE_SAVE, Wx::ART_MENU), 'Save file...')
    @tool_bar.add_separator
    @tool_bar.add_tool(Wx::ID_PRINT, 'Print', Wx::ArtProvider.get_bitmap(Wx::ART_PRINT, Wx::ART_MENU), 'Print...')
    @tool_bar.add_tool(Wx::ID_PREVIEW, 'Preview', Wx::ArtProvider.get_bitmap(Wx::ART_FIND, Wx::ART_MENU), 'Print preview...')
    @tool_bar.add_separator
    @tool_bar.add_tool(Wx::ID_COPY, 'Copy', Wx::ArtProvider.get_bitmap(Wx::ART_COPY, Wx::ART_MENU), 'Copy to clipboard')
    @tool_bar.add_tool(Wx::ID_CUT, 'Cut', Wx::ArtProvider.get_bitmap(Wx::ART_CUT, Wx::ART_MENU), 'Cut to clipboard')
    @tool_bar.add_tool(Wx::ID_PASTE, 'Paste', Wx::ArtProvider.get_bitmap(Wx::ART_PASTE, Wx::ART_MENU), 'Paste from clipboard')
    @tool_bar.add_separator
    @tool_bar.add_tool(Wx::ID_UNDO, 'Undo', Wx::ArtProvider.get_bitmap(Wx::ART_UNDO, Wx::ART_MENU), 'Undo')
    @tool_bar.add_tool(Wx::ID_REDO, 'Redo', Wx::ArtProvider.get_bitmap(Wx::ART_REDO, Wx::ART_MENU), 'Redo')
    @tool_bar.add_separator
    @tool_bar.add_check_tool(ID::T_GRID, 'Grid', Wx::Bitmap(:Grid), Wx::NULL_BITMAP, 'Show/hide grid')
    @tool_bar.add_check_tool(ID::T_SHADOW, 'Shadows', Wx::Bitmap(:Shadow), Wx::NULL_BITMAP, 'Show/hide shadows')
    @tool_bar.add_check_tool(ID::T_GC, 'Enhanced graphics context', Wx::Bitmap(:GC), Wx::NULL_BITMAP, 'Use enhanced graphics context (Wx::GraphicsContext)')
    @tool_bar.add_separator
    @tool_bar.add_radio_tool(ID::T_TOOL, 'Tool', Wx::Bitmap(:Tool), Wx::NULL_BITMAP, 'Design tool')
    @tool_bar.add_radio_tool(ID::T_RECTSHP, 'Rectangle', Wx::Bitmap(:Rect), Wx::NULL_BITMAP, 'Rectangle')
    @tool_bar.add_radio_tool(ID::T_SQUARESHP, 'Fixed rectangle', Wx::Bitmap(:FixedRect), Wx::NULL_BITMAP, 'Fixed rectangle')
    @tool_bar.add_radio_tool(ID::T_RNDRECTSHP, 'RoundRect', Wx::Bitmap(:RoundRect), Wx::NULL_BITMAP, 'Rounded rectangle')
    @tool_bar.add_radio_tool(ID::T_ELLIPSESHP, 'Ellipse', Wx::Bitmap(:Ellipse), Wx::NULL_BITMAP, 'Ellipse')
    @tool_bar.add_radio_tool(ID::T_CIRCLESHP, 'Circle', Wx::Bitmap(:Circle), Wx::NULL_BITMAP, 'Circle')
    @tool_bar.add_radio_tool(ID::T_DIAMONDSHP, 'Diamond', Wx::Bitmap(:Diamond), Wx::NULL_BITMAP, 'Diamond')
    @tool_bar.add_radio_tool(ID::T_TEXTSHP, 'Text', Wx::Bitmap(:Text), Wx::NULL_BITMAP, 'Text')
    @tool_bar.add_radio_tool(ID::T_EDITTEXTSHP, 'Editable text', Wx::Bitmap(:EditText), Wx::NULL_BITMAP, 'Editable text')
    @tool_bar.add_radio_tool(ID::T_BITMAPSHP, 'Bitmap', Wx::Bitmap(:Bitmap), Wx::NULL_BITMAP, 'Bitmap')
    @tool_bar.add_radio_tool(ID::T_GRIDSHP, 'Grid shape', Wx::Bitmap(:Grid), Wx::NULL_BITMAP, 'Grid shape')
    @tool_bar.add_radio_tool(ID::T_FLEXGRIDSHP, 'Flexible grid shape', Wx::Bitmap(:FlexGrid), Wx::NULL_BITMAP, 'Flexible grid shape')
    @tool_bar.add_radio_tool(ID::T_VBOXSHP, 'Vertical Box shape', Wx::Bitmap(:VBox), Wx::NULL_BITMAP, 'Vertical Box shape')
    @tool_bar.add_radio_tool(ID::T_HBOXSHP, 'Horizontal Box shape', Wx::Bitmap(:HBox), Wx::NULL_BITMAP, 'Horizontal Box shape')
    @tool_bar.add_radio_tool(ID::T_LINESHP, 'Line', Wx::Bitmap(:Line), Wx::NULL_BITMAP, 'Polyline connection')
    @tool_bar.add_radio_tool(ID::T_CURVESHP, 'Curve', Wx::Bitmap(:Curve), Wx::NULL_BITMAP, 'Curve connection')
    @tool_bar.add_radio_tool(ID::T_ORTHOSHP, 'Ortho line', Wx::Bitmap(:OrthoLine), Wx::NULL_BITMAP, 'Orthogonal connection')
    @tool_bar.add_radio_tool(ID::T_RNDORTHOSHP, 'Rounded ortho line', Wx::Bitmap(:RoundOrthoLine), Wx::NULL_BITMAP, 'Rounded orthogonal connection')
    @tool_bar.add_radio_tool(ID::T_STANDALONELINESHP, 'Stand alone line', Wx::Bitmap(:StandAloneLine), Wx::NULL_BITMAP, 'Stand alone line')
    @tool_bar.add_separator
    @tool_bar.add_tool(ID::T_ALIGN_LEFT, 'Align left', Wx::Bitmap(:AlignLeft), 'Align selected shapes to the left')
    @tool_bar.add_tool(ID::T_ALIGN_RIGHT, 'Align right', Wx::Bitmap(:AlignRight), 'Align selected shapes to the right')
    @tool_bar.add_tool(ID::T_ALIGN_TOP, 'Align top', Wx::Bitmap(:AlignTop), 'Align selected shapes to the top')
    @tool_bar.add_tool(ID::T_ALIGN_BOTTOM, 'Align bottom', Wx::Bitmap(:AlignBottom), 'Align selected shapes to the bottom')
    @tool_bar.add_tool(ID::T_ALIGN_MIDDLE, 'Align middle', Wx::Bitmap(:AlignMiddle), 'Align selected shapes to the middle')
    @tool_bar.add_tool(ID::T_ALIGN_CENTER, 'Align center', Wx::Bitmap(:AlignCenter), 'Align selected shapes to the center')
    @tool_bar.add_separator
    @tool_bar.add_control(@cpicker)
    @tool_bar.realize

    @status_bar.set_status_text('Ready')

    # initialize data members
    @tool_mode = MODE::DESIGN
    @show_grid = true
    @show_shadows = false

    centre
    
    # setup event handlers
    evt_close(:on_close)
    evt_menu(Wx::ID_EXIT, :on_exit)
    evt_menu(Wx::ID_NEW, :on_new)
    evt_menu(Wx::ID_OPEN, :on_load)
    evt_menu(Wx::ID_SAVE, :on_save)
    evt_menu(Wx::ID_UNDO, :on_undo)
    evt_menu(Wx::ID_REDO, :on_redo)
    evt_menu(Wx::ID_COPY, :on_copy)
    evt_menu(Wx::ID_CUT, :on_cut)
    evt_menu(Wx::ID_PASTE, :on_paste)
    evt_menu(Wx::ID_ABOUT, :on_about)
    evt_menu(Wx::ID_SELECTALL, :on_select_all)
    evt_menu(ID::M_SAVEASBITMAP, :on_export_to_bmp)
    evt_menu(Wx::ID_PRINT, :on_print)
    evt_menu(Wx::ID_PREVIEW, :on_print_preview)
    evt_menu(Wx::ID_PAGE_SETUP, :on_page_setup)
    evt_menu_range(ID::M_AUTOLAYOUT_FIRST, ID::M_AUTOLAYOUT_LAST, :on_auto_layout)
    evt_command_scroll(Wx::ID_ZOOM_FIT, :on_slider)
    evt_tool_range(ID::T_FIRST_TOOLMARKER, ID::T_LAST_TOOLMARKER, :on_tool)
    evt_colourpicker_changed(ID::T_COLORPICKER, :on_hover_color)
    evt_update_ui(Wx::ID_COPY, :on_update_copy)
    evt_update_ui(Wx::ID_CUT, :on_update_cut)
    evt_update_ui(Wx::ID_PASTE, :on_update_paste)
    evt_update_ui(Wx::ID_UNDO, :on_update_undo)
    evt_update_ui(Wx::ID_REDO, :on_update_redo)
    evt_update_ui_range(ID::T_FIRST_TOOLMARKER, ID::T_LAST_TOOLMARKER, :on_update_tool)
    evt_update_ui_range(ID::M_AUTOLAYOUT_FIRST, ID::M_AUTOLAYOUT_LAST, :on_update_auto_layout)
    evt_idle(:on_idle)
  end

  attr_accessor :tool_mode, :show_grid, :show_shadows

  attr_reader :zoom_slider

  def setup_frame
    if Wx::PLATFORM == 'WXMSW'
      set_size_hints([1024,700])
    else
      set_size_hints([1100,700])
    end
    
    @menu_bar = Wx::MenuBar.new(0)
    @file_menu = Wx::Menu.new
    @menu_bar.append(@file_menu, "&File")  
    
    @edit_menu = Wx::Menu.new
    @menu_bar.append(@edit_menu, "&Edit")  
    
    @auto_layout_menu = Wx::Menu.new
    @menu_bar.append(@auto_layout_menu, "&AutoLayout")  
    
    @help_menu = Wx::Menu.new
    @menu_bar.append(@help_menu, "&Help")  
    
    set_menu_bar(@menu_bar)
    
    @tool_bar = create_tool_bar(Wx::TB_HORIZONTAL, Wx::ID_ANY) 
    @tool_bar.realize 
    
    @status_bar = create_status_bar(1, Wx::STB_SIZEGRIP, Wx::ID_ANY)
    main_sizer = Wx::FlexGridSizer.new(2, 1, 0, 0)
    main_sizer.add_growable_col(0)
    main_sizer.add_growable_row(0)
    main_sizer.set_flexible_direction(Wx::BOTH)
    main_sizer.set_non_flexible_grow_mode(Wx::FLEX_GROWMODE_SPECIFIED)
    
    @canvas_panel = Wx::Panel.new(self, Wx::ID_ANY, style: Wx::TAB_TRAVERSAL)
    @canvas_panel.set_extra_style(Wx::WS_EX_BLOCK_EVENTS)
    
    @canvas_sizer = Wx::VBoxSizer.new
    
    @canvas_panel.set_sizer(@canvas_sizer)
    @canvas_panel.layout
    @canvas_sizer.fit(@canvas_panel)
    main_sizer.add(@canvas_panel, 1, Wx::EXPAND, 5)
    
    @zoom_slider = Wx::Slider.new(self, Wx::ID_ZOOM_FIT, 50, 2, 99, Wx::DEFAULT_POSITION, Wx::DEFAULT_SIZE, Wx::SL_HORIZONTAL)
    @zoom_slider.set_background_colour(Wx::SystemSettings.get_colour(Wx::SYS_COLOUR_BTNFACE))
    @zoom_slider.set_tool_tip("Set canvas scale") 
    
    main_sizer.add(@zoom_slider, 0, Wx::EXPAND, 5)
    
    set_sizer(main_sizer)
    layout
    
    centre(Wx::BOTH)
  end
  private :setup_frame

  protected

  def clean_up
    @diagram.set_shape_canvas(nil)
    @diagram.clear
    
    @thumb_frm.hide
    @thumb_frm.thumbnail.set_canvas(nil)
    
    destroy
  end

  # common events
  def on_close(_event)
    clean_up
  end

  def on_idle(_event)
    if @diagram.is_modified
      set_title('wxRuby ShapeFramework Demo (diagram is modified)')
    else
      set_title('wxRuby ShapeFramework Demo')
    end
  end

  # menu event handlers
  def on_exit(_event)
    clean_up
  end

  def on_new(_event)
    if Wx.message_box('Current chart will be lost. Do you want to proceed?',
                      'wxRuby ShapeFramework', Wx::YES_NO | Wx::ICON_QUESTION) == Wx::YES
      @diagram.clear

      @shape_canvas.clear_canvas_history
      @shape_canvas.save_canvas_state

      @shape_canvas.refresh
    end
  end

  def on_save(_event)
    Wx.FileDialog(self, 'Save canvas to file...', Dir.getwd, '', FILE_MASK, Wx::FD_SAVE) do |dlg|
      dlg_hook = DiagramFileDialog.new(dlg, compact: true)
      if dlg.show_modal == Wx::ID_OK
        begin
          path = dlg.get_path.dup
          if File.extname(path).empty?
            # determine extension to provide
            case dlg_hook.format
            when :json then path << '.json'
            when :yaml then path << '.yaml'
            when :xml then path << '.xml'
            else
              case dlg.get_filter_index
              when 0 then path << '.json'
              when 1 then path << '.yaml'
              when 2 then path << '.xml'
              end
            end
          end
          if !File.exist?(path) ||
            Wx.message_box("File #{path} already exists. Do you want to overwrite it?", 'Confirm', Wx::YES_NO) == Wx::YES
            @shape_canvas.save_canvas(path, compact: dlg_hook.compact, format: dlg_hook.format)

            Wx.MessageDialog(self, "The chart has been saved to '#{path}'.", 'wxRuby ShapeFramework', Wx::OK | Wx::ICON_INFORMATION)
          end
        rescue Exception => ex
          Wx.MessageDialog(self, "Failed to save the chart: #{ex.message}", 'wxRuby ShapeFramework', Wx::OK | Wx::ICON_ERROR)
        end
      end
    end
  end

  def on_load(_event)
    Wx.FileDialog(self, 'Load canvas from file...', Dir.getwd, '', FILE_MASK, Wx::FD_OPEN | Wx::FD_FILE_MUST_EXIST) do |dlg|
      dlg_hook = DiagramFileDialog.new(dlg)
      if dlg.show_modal == Wx::ID_OK
        begin
          @shape_canvas.load_canvas(dlg.get_path, format: dlg_hook.format)
          @diagram = @shape_canvas.get_diagram

          @zoom_slider.set_value((@shape_canvas.get_scale*50).to_i)

          @cpicker.set_colour(@shape_canvas.get_hover_colour)
        rescue Exception => ex
          Wx.MessageDialog(self, "Failed to load the chart: #{ex.message}", 'wxRuby ShapeFramework', Wx::OK | Wx::ICON_ERROR)
        end
      end
    end
  end

  def on_undo(_event)
    @shape_canvas.undo
  end

  def on_redo(_event)
    @shape_canvas.redo
  end

  def on_copy(_event)
    @shape_canvas.copy
  end

  def on_cut(_event)
    @shape_canvas.cut
  end

  def on_paste(_event)
    @shape_canvas.paste
  end

  def on_about(_event)
    Wx.message_box("wxRuby SF Demonstration Application\n" +
                     "wxRuby ShapeFramework version number: #{Wx::SF::VERSION}\n" +
                     "Martin Corino (c) 2023\n" +
                     "(original Michal Bliznak (c) 2007 - 2013)",
                   'wxRuby ShapeFramework')
  end

  def on_select_all(_event)
    @shape_canvas.select_all
  end

  def on_export_to_bmp(_event)
    Wx::FileDialog(self, 'Export canvas to image...', Dir.getwd, '',
                   'BMP Files (*.bmp)|*.bmp|GIF Files (*.gif)|(*.gif)|XPM Files (*.xpm)|*.xpm|PNG Files (*.png)|*.png|JPEG Files (*.jpg;*.jpeg)|*.jpg;*.jpeg', Wx::FD_SAVE) do |dlg|
      if dlg.show_modal == Wx::ID_OK
        type = Wx::BitmapType::BITMAP_TYPE_ANY
        
        case dlg.get_filter_index
        when 0
          type = Wx::BitmapType::BITMAP_TYPE_BMP
        when 1
          type = Wx::BitmapType::BITMAP_TYPE_GIF
        when 2
          type = Wx::BitmapType::BITMAP_TYPE_XPM
        when 3
          type = Wx::BitmapType::BITMAP_TYPE_PNG
        when 4
          type = Wx::BitmapType::BITMAP_TYPE_JPEG
        end
        
        if @shape_canvas.save_canvas_to_image(dlg.get_path, type: type, background: Wx::SF::WITH_BACKGROUND)
          Wx.message_box("The image has been saved to '#{dlg.get_path}'.", 'wxRuby SF Demonstration Application')
        else
          Wx.message_box("Unable to save image to '#{dlg.get_path}'.", 'wxRuby SF Demonstration Application', Wx::OK | Wx::ICON_ERROR)
        end
      end
    end
  end

  def on_print(_event)
    @shape_canvas.print
  end

  def on_print_preview(_event)
    @shape_canvas.print_preview
  end

  def on_page_setup(_event)
    @shape_canvas.page_setup
  end

  def on_auto_layout(event)
    Wx::SF::AutoLayout.layout(@shape_canvas, @auto_layout_menu.get_label(event.get_id))
    @shape_canvas.save_canvas_state
  end

  # toolbar event handlers
  def on_slider(_event)
    @shape_canvas.set_scale(@zoom_slider.get_value.to_f/50)
    @shape_canvas.refresh(false)
  end

  def on_tool(event)
    @shape_canvas.abort_interactive_connection if @shape_canvas.get_mode == Wx::SF::ShapeCanvas::MODE::CREATECONNECTION

    case event.get_id
    when ID::T_GRID
      @show_grid = !@show_grid
			if @show_grid 
        @shape_canvas.add_style(Wx::SF::ShapeCanvas::STYLE::GRID_SHOW)
        @shape_canvas.add_style(Wx::SF::ShapeCanvas::STYLE::GRID_USE)
			else
				@shape_canvas.remove_style(Wx::SF::ShapeCanvas::STYLE::GRID_SHOW)
				@shape_canvas.remove_style(Wx::SF::ShapeCanvas::STYLE::GRID_USE)
      end
      @shape_canvas.refresh(false)

    when ID::T_SHADOW
      @show_shadows = !@show_shadows

      @shape_canvas.show_shadows(@show_shadows, Wx::SF::ShapeCanvas::SHADOWMODE::ALL)
      # also shadows for topmost shapes only are allowed:
      # @shape_canvas.show_shadows(@show_shadows, Wx::SF::ShapeCanvas::SHADOWMODE::TOPMOST)
      @shape_canvas.refresh(false)

    when ID::T_GC
			if Wx.has_feature?(:USE_GRAPHICS_CONTEXT)
        Wx::SF::ShapeCanvas.enable_gc(!Wx::SF::ShapeCanvas.gc_enabled?)
        # update all shapes in the manager
        @diagram.update_all
        # refresh shape canvas
        @shape_canvas.refresh(false)
			else
        Wx.message_box('Could not enable enhanced graphics context due to wxUSE_GRAPHICS_CONTEXT=0', 'wxRuby ShapeFramework', Wx::OK | Wx::ICON_WARNING)
			end

    when ID::T_BITMAPSHP
      @tool_mode = MODE::BITMAP

    when ID::T_CIRCLESHP
      @tool_mode = MODE::CIRCLE

    when ID::T_CURVESHP
      @tool_mode = MODE::CURVE

    when ID::T_ORTHOSHP
      @tool_mode = MODE::ORTHOLINE

    when ID::T_RNDORTHOSHP
      @tool_mode = MODE::ROUNDORTHOLINE

    when ID::T_DIAMONDSHP
      @tool_mode = MODE::DIAMOND

    when ID::T_EDITTEXTSHP
      @tool_mode = MODE::EDITTEXT

    when ID::T_ELLIPSESHP
      @tool_mode = MODE::ELLIPSE

    when ID::T_GRIDSHP
      @tool_mode = MODE::GRID

    when ID::T_FLEXGRIDSHP
      @tool_mode = MODE::FLEXGRID

    when ID::T_VBOXSHP
      @tool_mode = MODE::VBOX

    when ID::T_HBOXSHP
      @tool_mode = MODE::HBOX

    when ID::T_LINESHP
      @tool_mode = MODE::LINE

    when ID::T_STANDALONELINESHP
      @tool_mode = MODE::STANDALONELINE

    when ID::T_RECTSHP
      @tool_mode = MODE::RECT

    when ID::T_RNDRECTSHP
      @tool_mode = MODE::ROUNDRECT

    when ID::T_SQUARESHP
      @tool_mode = MODE::FIXEDRECT

    when ID::T_TEXTSHP
      @tool_mode = MODE::TEXT

    when ID::T_TOOL
      @tool_mode = MODE::DESIGN

    when ID::T_ALIGN_LEFT
      @shape_canvas.align_selected(Wx::SF::ShapeCanvas::HALIGN::LEFT, Wx::SF::ShapeCanvas::VALIGN::NONE)

    when ID::T_ALIGN_RIGHT
      @shape_canvas.align_selected(Wx::SF::ShapeCanvas::HALIGN::RIGHT, Wx::SF::ShapeCanvas::VALIGN::NONE)

    when ID::T_ALIGN_CENTER
      @shape_canvas.align_selected(Wx::SF::ShapeCanvas::HALIGN::CENTER, Wx::SF::ShapeCanvas::VALIGN::NONE)

    when ID::T_ALIGN_TOP
      @shape_canvas.align_selected(Wx::SF::ShapeCanvas::HALIGN::NONE, Wx::SF::ShapeCanvas::VALIGN::TOP)

    when ID::T_ALIGN_BOTTOM
      @shape_canvas.align_selected(Wx::SF::ShapeCanvas::HALIGN::NONE, Wx::SF::ShapeCanvas::VALIGN::BOTTOM)

    when ID::T_ALIGN_MIDDLE
      @shape_canvas.align_selected(Wx::SF::ShapeCanvas::HALIGN::NONE, Wx::SF::ShapeCanvas::VALIGN::MIDDLE)

    else
      event.skip
    end
  end

  def on_hover_color(event)
    @shape_canvas.set_hover_colour(event.get_colour)
  end

  def on_update_copy(event)
    event.enable(@shape_canvas.can_copy?) if @shape_canvas
  end

  def on_update_cut(event)
    event.enable(@shape_canvas.can_cut?) if @shape_canvas
  end

  def on_update_paste(event)
    event.enable(@shape_canvas.can_paste?) if @shape_canvas
  end

  def on_update_undo(event)
    event.enable(@shape_canvas.can_undo?) if @shape_canvas
  end

  def on_update_redo(event)
    event.enable(@shape_canvas.can_redo?) if @shape_canvas
  end

  def on_update_tool(event)
    case event.get_id
    when ID::T_GRID
      event.check(@show_grid)

    when ID::T_GC
      event.check(Wx::SF::ShapeCanvas.gc_enabled?)

    when ID::T_BITMAPSHP
      event.check(@tool_mode == MODE::BITMAP)

    when ID::T_CIRCLESHP
      event.check(@tool_mode == MODE::CIRCLE)

    when ID::T_CURVESHP
      event.check(@tool_mode == MODE::CURVE)

    when ID::T_ORTHOSHP
      event.check(@tool_mode == MODE::ORTHOLINE)

    when ID::T_RNDORTHOSHP
      event.check(@tool_mode == MODE::ROUNDORTHOLINE)

    when ID::T_DIAMONDSHP
      event.check(@tool_mode == MODE::DIAMOND)

    when ID::T_EDITTEXTSHP
      event.check(@tool_mode == MODE::EDITTEXT)

    when ID::T_ELLIPSESHP
      event.check(@tool_mode == MODE::ELLIPSE)

    when ID::T_GRIDSHP
      event.check(@tool_mode == MODE::GRID)

    when ID::T_FLEXGRIDSHP
      event.check(@tool_mode == MODE::FLEXGRID)

    when ID::T_VBOXSHP
      event.check(@tool_mode == MODE::VBOX)

    when ID::T_HBOXSHP
      event.check(@tool_mode == MODE::HBOX)

    when ID::T_LINESHP
      event.check(@tool_mode == MODE::LINE)

    when ID::T_STANDALONELINESHP
      event.check(@tool_mode == MODE::STANDALONELINE)

    when ID::T_RECTSHP
      event.check(@tool_mode == MODE::RECT)

    when ID::T_RNDRECTSHP
      event.check(@tool_mode == MODE::ROUNDRECT)

    when ID::T_SQUARESHP
      event.check(@tool_mode == MODE::FIXEDRECT)

    when ID::T_TEXTSHP
      event.check(@tool_mode == MODE::TEXT)

    when ID::T_TOOL
      event.check(@tool_mode == MODE::DESIGN)

    when ID::T_ALIGN_RIGHT,
         ID::T_ALIGN_LEFT,
         ID::T_ALIGN_TOP,
         ID::T_ALIGN_BOTTOM,
         ID::T_ALIGN_MIDDLE,
         ID::T_ALIGN_CENTER
      event.enable(@shape_canvas.can_align_selected) if @shape_canvas

    else
      event.skip
    end
  end

  def on_update_auto_layout(event)
    event.enable(!@diagram.empty?)
  end
end

Wx::App.run do
  MainFrame.new(nil).show
end
