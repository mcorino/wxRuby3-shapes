# Wx::SF - Demo FrameCanvas
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes'

class FrameCanvas < Wx::SF::ShapeCanvas

  module POPUP_ID
    include Wx::IDHelper

    # commmon
    STYLE = self.next_id
    HOVER_COLOR = self.next_id
    HALIGN = self.next_id
    VALIGN = self.next_id
    HBORDER = self.next_id
    VBORDER = self.next_id

    # rect
    FILL_BRUSH = self.next_id
    FILL_COLOR = self.next_id
    FILL_STYLE = self.next_id
    BORDER_PEN = self.next_id
    BORDER_COLOR = self.next_id
    BORDER_WIDTH = self.next_id
    BORDER_STYLE = self.next_id

    # line
    LINE_PEN = self.next_id
    LINE_COLOR = self.next_id
    LINE_WIDTH = self.next_id
    LINE_STYLE = self.next_id
    LINE_ARROWS = self.next_id
    SRC_ARROW = self.next_id
    TRG_ARROW = self.next_id

    DUMP = self.next_id
  end

  # Constructor
  # @param [Wx::SF::Diagram] diagram shape diagram
  # @param [Wx::Window] parent Parent window
  # @param [Integer] id Window ID
  def initialize(diagram, parent, id = Wx::ID_ANY)
    super(diagram, parent, id)

    # initialize grid
    add_style(STYLE::GRID_USE)
    add_style(STYLE::GRID_SHOW)
    # distances between grid lines can be modified via following function:
    set_grid_line_mult(10)
    # grid line style can be set as follows:
    set_grid_style(Wx::PenStyle::PENSTYLE_SHORT_DASH)

    # canvas background can be printed/omitted during the canvas printing job
    #add_style(STYLE::PRINT_BACKGROUND)

    # adjust the printed drawing align and style if needed
    # set_print_v_align(VALIGN::TOP)
    # set_print_h_align(HALIGN::LEFT)
    # set_print_mode(PRINTMODE::MAP_TO_MARGINS)

    # the canvas background can be filled with a solid colour ...
    # remove_style(STYLE::GRADIENT_BACKGROUND)
    # set_background_colour(DEFAULT::SHAPECANVAS_BACKGROUNDCOLOR)
    # ... or by a gradient fill
    add_style(STYLE::GRADIENT_BACKGROUND)
    set_gradient_from(DEFAULT.gradient_from)
    set_gradient_to(DEFAULT.gradient_to)

    # also shadows style can be set here:
    # set_shadow_fill(Wx::Brush.new(Wx::Colour.new(100, 100, 100), Wx::CROSSDIAG_HATCH)) # standard values can be DEFAULT::SHAPECANVAS_SHADOWBRUSH or DEFAULT::SHAPECANVAS_SHADOWCOLOR
    # set_shadow_offset(Wx::RealPoint.new(7, 7))

    # now you can use also these styles...

    # remove_style(STYLE::HOVERING)
    # remove_style(STYLE::HIGHLIGHTING)
    # remove_style(STYLE::UNDOREDO)
    # remove_style(STYLE::DND)
    # remove_style(STYLE::CLIPBOARD)
    # remove_style(STYLE::MULTI_SIZE_CHANGE)
    # remove_style(STYLE::MULTI_SELECTION)

    # a style flag presence can be tested like this:
    # if( has_style?(STYLE::GRID_USE) ) do_something()

    # multiple styles can be set in this way:
    # set_style(STYLE::GRID_USE | STYLE::GRID_SHOW) ... or ...
    # set_style(STYLE::DEFAULT_CANVAS_STYLE)

    # process mouse wheel if needed
    add_style(STYLE::PROCESS_MOUSEWHEEL)
    # set scale boundaries applied on mouse wheel scale change
    set_min_scale(0.1)
    set_max_scale(2.0)

    # specify accepted shapes...
    get_diagram.clear_accepted_shapes
    get_diagram.accept_shape(Wx::SF::ACCEPT_ALL)

    # ... in addition, specify accepted top shapes (i.e. shapes that can be placed
    # directly onto the canvas)
    # get_diagram.clear_accepted_top_shapes
    # get_diagram.accept_top_shape(Wx::SF::RectShape)

    # get main application frame
    @parent_frame = Wx.get_app.get_top_window
  end

  def on_left_down(event)
    shape = nil
    case @parent_frame.tool_mode
    when MainFrame::MODE::BITMAP
      Wx::FileDialog(self, "Load bitmap image...", __dir__, '', 'BMP Files (*.bmp)|*.bmp', Wx::FD_OPEN | Wx::FD_FILE_MUST_EXIST) do |dlg|
  
        if dlg.show_modal == Wx::ID_OK
          _, shape = get_diagram.create_shape(Wx::SF::BitmapShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
          if shape
            # create relative path
            # wxFileName path( dlg.GetPath() )
            # path.MakeRelativeTo( wxGetCwd() )
            # create image from BMP file
            # ((wxSFBitmapShape*)shape).CreateFromFile( path.GetFullPath(), Wx::BITMAP_TYPE_BMP )
            shape.create_from_file(dlg.get_path, Wx::BitmapType::BITMAP_TYPE_BMP)
  
            # set shape policy
            shape.accept_connection(Wx::SF::ACCEPT_ALL)
            shape.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
            shape.accept_trg_neighbour(Wx::SF::ACCEPT_ALL)
          end
        end
      end
    when MainFrame::MODE::TEXT, MainFrame::MODE::EDITTEXT
      Wx::TextEntryDialog(self, '', 'Enter text', 'Hello World!') do |dlg|
        if dlg.show_modal == Wx::ID_OK
          if @parent_frame.tool_mode == MainFrame::MODE::TEXT
            _, shape = get_diagram.create_shape(Wx::SF::TextShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
          else
            _, shape = get_diagram.create_shape(Wx::SF::EditTextShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
            # editable text shapes can be forced to be multiline at default like this:
            # shape.force_multiline( true )

            # also edit control type can be set here like this:
            # shape.set_edit_type(Wx::SF::EditTextShape::EDITTYPE::DIALOG)
          end
        end

        if shape
          shape.set_text(dlg.get_value)

          # set alignment
          shape.set_v_align(Wx::SF::Shape::VALIGN::TOP)
          shape.set_h_align(Wx::SF::Shape::HALIGN::CENTER)
          shape.set_v_border(10.0)
          shape.update

          # set shapes policy
          shape.accept_connection(Wx::SF::ACCEPT_ALL)
          shape.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
          shape.accept_trg_neighbour(Wx::SF::TextShape)
          shape.accept_trg_neighbour(Wx::SF::EditTextShape)
        end
      end

    when MainFrame::MODE::DIAMOND
      _, shape = get_diagram.create_shape(Wx::SF::DiamondShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      if shape
        # set shape policy
        shape.accept_child(Wx::SF::TextShape)
        shape.accept_child(Wx::SF::EditTextShape)

        shape.accept_connection(Wx::SF::ACCEPT_ALL)
        shape.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
        shape.accept_trg_neighbour(Wx::SF::ACCEPT_ALL)
      end

    when MainFrame::MODE::FIXEDRECT
      _, shape = get_diagram.create_shape(Wx::SF::SquareShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      if shape
        # set shape policy
        shape.accept_child(Wx::SF::TextShape)
        shape.accept_child(Wx::SF::EditTextShape)

        shape.accept_connection(Wx::SF::ACCEPT_ALL)
        shape.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
        shape.accept_trg_neighbour(Wx::SF::ACCEPT_ALL)
      end

    when MainFrame::MODE::ROUNDRECT
      _, shape = get_diagram.create_shape(Wx::SF::RoundRectShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      if shape
        # set shape policy
        shape.accept_child(Wx::SF::TextShape)
        shape.accept_child(Wx::SF::EditTextShape)

        shape.accept_connection(Wx::SF::ACCEPT_ALL)
        shape.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
        shape.accept_trg_neighbour(Wx::SF::ACCEPT_ALL)
      end

    when MainFrame::MODE::RECT
      _, shape = get_diagram.create_shape(Wx::SF::RectShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      if shape
        # set shape policy
        shape.accept_child(Wx::SF::ACCEPT_ALL)

        shape.accept_connection(Wx::SF::ACCEPT_ALL)
        shape.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
        shape.accept_trg_neighbour(Wx::SF::ACCEPT_ALL)
        
        # child shapes can be locked accordingly to their parent's origin if the parent is resized
        # shape.add_style(Wx::SF::Shape::STYLE::LOCK_CHILDREN)

        # shapes can have fixed connection points defined in the following way:
        cp = shape.add_connection_point(Wx::SF::ConnectionPoint::CPTYPE::CENTERLEFT)
        # also direction of connected orthogonal lines can be set in the following way:
        cp.set_ortho_direction(Wx::SF::ConnectionPoint::CPORTHODIR::HORIZONTAL)
        cp = shape.add_connection_point(Wx::SF::ConnectionPoint::CPTYPE::CENTERRIGHT)
        cp.set_ortho_direction(Wx::SF::ConnectionPoint::CPORTHODIR::HORIZONTAL)
        cp = shape.add_connection_point(Wx::SF::ConnectionPoint::CPTYPE::TOPMIDDLE)
        cp.set_ortho_direction(Wx::SF::ConnectionPoint::CPORTHODIR::VERTICAL)
        cp = shape.add_connection_point(Wx::SF::ConnectionPoint::CPTYPE::BOTTOMMIDDLE)
        cp.set_ortho_direction(Wx::SF::ConnectionPoint::CPORTHODIR::VERTICAL)
        # user can define also any number of CUSTOM connection points placed relatively to the
        # parent shape's bounding box ("25, 50" here means 25% of width and 50% of height):
        shape.add_connection_point([25, 50])
        shape.add_connection_point([75, 50])
        # in this case the line connection can be assigned to one of the defined
        # fixed connection points only.
      end

    when MainFrame::MODE::GRID, MainFrame::MODE::FLEXGRID
      if @parent_frame.tool_mode == MainFrame::MODE::GRID
        _, shape = get_diagram.create_shape(Wx::SF::GridShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      else
        _, shape = get_diagram.create_shape(Wx::SF::FlexGridShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      end

      if shape
        # set visual style
        shape.set_fill(Wx::TRANSPARENT_BRUSH)
        shape.set_border(Wx::Pen.new(Wx::BLACK, 1, Wx::PenStyle::PENSTYLE_DOT))

        # number of rows and columns cas be set here (default grid dimension is 3x3) ...
        # shape.set_dimensions(2, 2)

        # ... as well as the cell spaces (default grid cellspace is 5).
        # shape.set_cell_space(0)

        # set shape policy
        shape.accept_child(Wx::SF::ACCEPT_ALL)

        shape.accept_connection(Wx::SF::ACCEPT_ALL)
        shape.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
        shape.accept_trg_neighbour(Wx::SF::ACCEPT_ALL)

        # insert some shapes into the grid from code here (it can also be done interactively by drag&drop operations).
        # shapes inserted to the grid can be aligned relatively to its grid cell region
        _, inner_shape = get_diagram.create_shape(Wx::SF::EllipseShape, Wx::SF::DONT_SAVE_STATE)
        inner_shape.set_v_align(Wx::SF::Shape::VALIGN::EXPAND )
        shape.append_to_grid(inner_shape)
        # add some another shapes...
        _, inner_shape = get_diagram.create_shape(Wx::SF::DiamondShape, Wx::SF::DONT_SAVE_STATE)
        shape.append_to_grid(inner_shape)
        # shapes can be also inserted before given lexicographic position (at the first position in self when) in self way ...
        _, inner_shape = get_diagram.create_shape(Wx::SF::RoundRectShape, Wx::SF::DONT_SAVE_STATE)
        shape.insert_to_grid(0, inner_shape)
        # ... or can replace previously assigned shape at the position specified by row and column indexes
        # (note that the previous shape at the given position (if exists) will be moved to the grid's last lexicographic position).
        _, inner_shape = get_diagram.create_shape(Wx::SF::CircleShape, Wx::SF::DONT_SAVE_STATE)
        shape.insert_to_grid(1, 0, inner_shape)

        # also control shapes can be managed by the grid shape.
        # _, ctrl = get_diagram.create_shape(Wx::SF::ControlShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
        # if ctrl )
        #	  ctrl.set_v_align(Wx::SF::Shape::VALIGN::EXPAND)
        #	  ctrl.set_h_align(Wx::SF::Shape::HALIGN::EXPAND)
        #	  ctrl.set_control(Wx::Button.new( self, Wx::ID_ANY, "Test"))
        #	  shape.append_to_grid(ctrl)
        # end

        # update the grid
        shape.update
      end

    when MainFrame::MODE::VBOX, MainFrame::MODE::HBOX
      if @parent_frame.tool_mode == MainFrame::MODE::VBOX
        _, shape = get_diagram.create_shape(Wx::SF::VBoxShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      else
        _, shape = get_diagram.create_shape(Wx::SF::HBoxShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      end

      if shape
        # set visual style
        shape.set_fill(Wx::TRANSPARENT_BRUSH)

        # spacing can be set here (default spacing is 3).
        # shape.set_spacing(0)

        # set shape policy
        shape.accept_child(Wx::SF::ACCEPT_ALL)

        shape.accept_connection(Wx::SF::ACCEPT_ALL)
        shape.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
        shape.accept_trg_neighbour(Wx::SF::ACCEPT_ALL)

        if @parent_frame.tool_mode == MainFrame::MODE::VBOX

        else
          # insert some shapes into the grid from code here (it can also be done interactively by drag&drop operations).
          # shapes inserted to the grid can be aligned relatively to its grid cell region
          _, inner_shape = get_diagram.create_shape(Wx::SF::EllipseShape, Wx::SF::DONT_SAVE_STATE)
          inner_shape.set_v_align(Wx::SF::Shape::VALIGN::EXPAND )
          shape.append_to_box(inner_shape)
          # add another shape...
          _, inner_shape = get_diagram.create_shape(Wx::SF::DiamondShape, Wx::SF::DONT_SAVE_STATE)
          shape.append_to_box(inner_shape)
        end

        # also control shapes can be managed by the grid shape.
        # _, ctrl = get_diagram.create_shape(Wx::SF::ControlShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
        # if ctrl )
        #	  ctrl.set_v_align(Wx::SF::Shape::VALIGN::EXPAND)
        #	  ctrl.set_h_align(Wx::SF::Shape::HALIGN::EXPAND)
        #	  ctrl.set_control(Wx::Button.new( self, Wx::ID_ANY, "Test"))
        #	  shape.append_to_box(ctrl)
        # end

        # update the box
        shape.update
      end

    when MainFrame::MODE::ELLIPSE
      _, shape = get_diagram.create_shape(Wx::SF::EllipseShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      if shape
        # set shape policy
        shape.accept_child(Wx::SF::TextShape)
        shape.accept_child(Wx::SF::EditTextShape)

        shape.accept_connection(Wx::SF::ACCEPT_ALL)
        shape.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
        shape.accept_trg_neighbour(Wx::SF::ACCEPT_ALL)
      end

    when MainFrame::MODE::CIRCLE
      _, shape = get_diagram.create_shape(Wx::SF::CircleShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      if shape
        # set shape policy
        shape.remove_style(Wx::SF::Shape::STYLE::SIZE_CHANGE)

        shape.accept_child(Wx::SF::TextShape)
        shape.accept_child(Wx::SF::EditTextShape)

        shape.accept_connection(Wx::SF::ACCEPT_ALL)
        shape.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
        shape.accept_trg_neighbour(Wx::SF::ACCEPT_ALL)
      end

    when MainFrame::MODE::LINE
      if get_mode == MODE::READY
        start_interactive_connection(Wx::SF::LineShape, event.get_position)
        # interactive connection can be created also from existing object for example
        # if some connection properties should be modified before the connection creation
        # process is started:
        # start_interactive_connection(Wx::SF::LineShape.new, event.get_position)
      else
        super
      end

     when MainFrame::MODE::CURVE
        if get_mode == MODE::READY
          start_interactive_connection(Wx::SF::CurveShape, event.get_position)
        else
          super
        end

     when MainFrame::MODE::ORTHOLINE
        if get_mode == MODE::READY
          start_interactive_connection(Wx::SF::OrthoLineShape, event.get_position)
        else
          super
        end

    when MainFrame::MODE::ROUNDORTHOLINE
        if get_mode == MODE::READY
          start_interactive_connection(Wx::SF::RoundOrthoLineShape, event.get_position)
        else
          super
        end

    when MainFrame::MODE::STANDALONELINE
      _, shape = get_diagram.create_shape(Wx::SF::LineShape, event.get_position, Wx::SF::DONT_SAVE_STATE)
      if shape
        # set the line to be stand-alone
        shape.set_stand_alone(true)

        shape.set_src_point((event.get_position - [50, 0]).to_real_point)
        shape.set_trg_point((event.get_position + [50, 0]).to_real_point)

        # line's ending style can be set as follows:
        # shape.set_src_arrow(Wx::SF::CircleArrow)
        # shape.set_trg_arrow(Wx::SF::CircleArrow)

        shape.accept_child(Wx::SF::TextShape)
        shape.accept_child(Wx::SF::EditTextShape)
      end

    else
      # do default actions
      super
    end
  
    if shape
      show_shadows(@parent_frame.show_shadows, SHADOWMODE::ALL)

      save_canvas_state

      @parent_frame.tool_mode = MainFrame::MODE::DESIGN unless event.control_down

      shape.refresh
    end
  end

  class FloatDialog < Wx::Dialog
    def initialize(parent, title, label: 'Value:', value: 0.0, min: 0.0, max: 100.0, inc: 0.1)
      super(parent, Wx::ID_ANY, title, size: [400, -1])
      sizer_top = Wx::VBoxSizer.new
      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::StaticText.new(self, Wx::ID_ANY, label), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @spin_ctrl = Wx::SpinCtrlDouble.new(self, Wx::ID_ANY, value.to_s, min: min, max: max, inc: inc)
      sizer.add(@spin_ctrl, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::ALL, 5))
      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::Button.new(self, Wx::ID_OK, "&Ok"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::Button.new(self, Wx::ID_CANCEL, "&Cancel"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::RIGHT, 80))

      set_auto_layout(true)
      set_sizer(sizer_top)

      sizer_top.set_size_hints(self)
      sizer_top.fit(self)
    end

    def get_value
      @spin_ctrl.get_value
    end
  end

  def create_shape_popup
    menu = Wx::Menu.new
    menu.append(POPUP_ID::STYLE, 'Change style', 'Change style')
    menu.append(POPUP_ID::HOVER_COLOR, 'Change hover colour', 'Change hover colour')
    menu.append(POPUP_ID::HALIGN, 'Change horizontal alignment', 'Change horizontal alignment')
    menu.append(POPUP_ID::VALIGN, 'Change vertical alignment', 'Change vertical alignment')
    menu.append(POPUP_ID::HBORDER, 'Change horizontal margin', 'Change horizontal margin')
    menu.append(POPUP_ID::VBORDER, 'Change vertical margin', 'Change vertical margin')

    @rect_mi = []
    submenu = Wx::Menu.new
    submenu.append(POPUP_ID::FILL_COLOR, 'Change fill colour', 'Change fill colour')
    submenu.append(POPUP_ID::FILL_STYLE, 'Change fill style', 'Change fill style')
    @rect_mi << Wx::MenuItem.new(menu, POPUP_ID::FILL_BRUSH, 'Change fill', '', Wx::ItemKind::ITEM_NORMAL, submenu)
    submenu = Wx::Menu.new
    submenu.append(POPUP_ID::BORDER_COLOR, 'Change border colour', 'Change border colour')
    submenu.append(POPUP_ID::BORDER_STYLE, 'Change border style', 'Change border style')
    submenu.append(POPUP_ID::BORDER_WIDTH, 'Change border width', 'Change border width')
    @rect_mi << Wx::MenuItem.new(menu, POPUP_ID::BORDER_PEN, 'Change border', '', Wx::ItemKind::ITEM_NORMAL, submenu)

    @line_mi = []
    submenu = Wx::Menu.new
    submenu.append(POPUP_ID::LINE_COLOR, 'Change line colour', 'Change line colour')
    submenu.append(POPUP_ID::LINE_STYLE, 'Change line style', 'Change line style')
    submenu.append(POPUP_ID::LINE_WIDTH, 'Change line width', 'Change line width')
    @line_mi << Wx::MenuItem.new(menu, POPUP_ID::LINE_PEN, 'Change line', '', Wx::ItemKind::ITEM_NORMAL, submenu)
    submenu = Wx::Menu.new
    submenu.append(POPUP_ID::SRC_ARROW, 'Change source arrow', 'Change source arrow')
    submenu.append(POPUP_ID::TRG_ARROW, 'Change target arrow', 'Change target arrow')
    @line_mi << Wx::MenuItem.new(menu, POPUP_ID::LINE_ARROWS, 'Change arrows', '', Wx::ItemKind::ITEM_NORMAL, submenu)

    menu.append_separator
    menu.append(POPUP_ID::DUMP, 'Show serialized state', 'Show serialized state')
    menu
  end
  private :create_shape_popup

  def get_shape_popup(shape)
    @popup ||= create_shape_popup
    case shape
    when Wx::SF::RectShape
      @popup.remove(POPUP_ID::LINE_PEN) if @popup.find_item(POPUP_ID::LINE_PEN)
      @popup.remove(POPUP_ID::LINE_ARROWS) if @popup.find_item(POPUP_ID::LINE_ARROWS)
      n = @popup.get_menu_item_count
      @rect_mi.reverse.each { |mi| @popup.insert(n-2, mi) unless  @popup.find_item(mi.id) }
    when Wx::SF::LineShape
      @popup.remove(POPUP_ID::FILL_BRUSH) if @popup.find_item(POPUP_ID::FILL_BRUSH)
      @popup.remove(POPUP_ID::BORDER_PEN) if @popup.find_item(POPUP_ID::BORDER_PEN)
      n = @popup.get_menu_item_count
      @line_mi.reverse.each { |mi| @popup.insert(n-2, mi) unless @popup.find_item(mi.id) }
    else
      @popup.remove(POPUP_ID::LINE_PEN) if @popup.find_item(POPUP_ID::LINE_PEN)
      @popup.remove(POPUP_ID::LINE_ARROWS) if @popup.find_item(POPUP_ID::LINE_ARROWS)
      @popup.remove(POPUP_ID::FILL_BRUSH) if @popup.find_item(POPUP_ID::FILL_BRUSH)
      @popup.remove(POPUP_ID::BORDER_PEN) if @popup.find_item(POPUP_ID::BORDER_PEN)
    end
    @popup
  end
  private :get_shape_popup

  class << self
    def get_style_choices(enum, exclude: nil)
      enumerators = enum.enumerators.values
      enumerators.reject!.each { |e| exclude ? exclude.call(enum[e]) : true }
      enumerators.collect { |id| id.to_s }
    end

    def get_style_index(enumerator, exclude: nil)
      enum = enumerator.class
      enumerators = enum.enumerators.keys
      enumerators.reject!.each { |e| exclude ? exclude.call(e) : true }
      enumerators.index(enumerator.to_i)
    end

    def index_to_style(enum, index, exclude: nil)
      enumerators = enum.enumerators.values
      enumerators.reject!.each { |e| exclude ? exclude.call(enum[e]) : true }
      enum[enumerators[index]]
    end

    def selections_to_style(enum, selections, exclude: nil)
      enumerators = enum.enumerators.keys
      enumerators.reject!.each { |e| exclude ? exclude.call(e) : true }
      selections.inject(enum.new(0)) do |mask, ix|
        mask | enumerators[ix]
      end
    end

    def style_to_selections(enum, style, exclude: nil)
      sel = []
      enumerators = enum.enumerators.keys
      enumerators.reject!.each { |e| exclude ? exclude.call(e) : true }
      enumerators.each_with_index do |eval, ix|
        sel << ix if style.allbits?(eval)
      end
      sel
    end
  end

  def get_style_choices(enum, exclude: nil)
    self.class.get_style_choices(enum, exclude: exclude)
  end

  def get_style_index(enumerator, exclude: nil)
    self.class.get_style_index(enumerator, exclude: exclude)
  end

  def index_to_style(enum, index, exclude: nil)
    self.class.index_to_style(enum, index, exclude: exclude)
  end

  def selections_to_style(enum, selections, exclude: nil)
    self.class.selections_to_style(enum, selections, exclude: exclude)
  end

  def style_to_selections(enum, style, exclude: nil)
    self.class.style_to_selections(enum, style, exclude: exclude)
  end

  class ArrowDialog < Wx::Dialog

    def initialize(parent, title, arrow)
      super(parent, Wx::ID_ANY, title)
      sizer_top = Wx::VBoxSizer.new

      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::StaticText.new(self, Wx::ID_ANY, 'Arrow type:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @arrow = Wx::ComboBox.new(self, Wx::ID_ANY, arrow_type(arrow),
                                choices: %w[None Open Prong Crossbar DoubleCrossbar Cup Solid Diamond Circle Square])
      sizer.add(@arrow, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::ALL, 5))

      @line_szr = Wx::StaticBoxSizer.new(Wx::Orientation::VERTICAL, self, 'Pen')
      sizer = Wx::HBoxSizer.new
      @line_pen_rb = Wx::RadioButton.new(@line_szr.static_box, Wx::ID_ANY, 'Use line pen', style: Wx::RB_GROUP)
      sizer.add(@line_pen_rb, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @custom_pen_rb = Wx::RadioButton.new(@line_szr.static_box, Wx::ID_ANY, 'Use custom pen')
      sizer.add(@custom_pen_rb, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @line_szr.add(sizer, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::StaticText.new(@line_szr.static_box, Wx::ID_ANY, 'Colour:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @line_clr = Wx::ColourPickerCtrl.new(@line_szr.static_box, Wx::ID_ANY)
      sizer.add(@line_clr, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::StaticText.new(@line_szr.static_box, Wx::ID_ANY, 'Width:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @line_wdt = Wx::SpinCtrl.new(@line_szr.static_box, Wx::ID_ANY)
      sizer.add(@line_wdt, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::StaticText.new(@line_szr.static_box, Wx::ID_ANY, 'Style:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @line_style = Wx::ComboBox.new(@line_szr.static_box, Wx::ID_ANY,
                                     choices: get_style_choices(Wx::PenStyle,
                                                                exclude: ->(e) { e ==  Wx::PenStyle::PENSTYLE_INVALID }))
      sizer.add(@line_style, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @line_szr.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::ALL, 5))
      sizer_top.add(@line_szr, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::ALL, 5))

      if Wx::SF::LineArrow === arrow
        @line_pen_rb.value = true
        @line_clr.colour = arrow.pen.colour
        @line_wdt.value = arrow.pen.width
        @line_style.selection = get_style_index(arrow.pen.style,
                                                exclude: ->(e) { e ==  Wx::PenStyle::PENSTYLE_INVALID })
        @line_clr.enable(false)
        @line_wdt.enable(false)
        @line_style.enable(false)
      else
        @line_szr.static_box.enable(false)
      end

      @fill_szr = Wx::StaticBoxSizer.new(Wx::Orientation::HORIZONTAL, self, 'Fill')
      @fill_szr.add(Wx::StaticText.new(@fill_szr.static_box, Wx::ID_ANY, 'Colour:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @fill_clr = Wx::ColourPickerCtrl.new(@fill_szr.static_box, Wx::ID_ANY)
      @fill_szr.add(@fill_clr, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @fill_szr.add(Wx::StaticText.new(@fill_szr.static_box, Wx::ID_ANY, 'Style:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @fill_style = Wx::ComboBox.new(@fill_szr.static_box, Wx::ID_ANY,
                                     choices: get_style_choices(Wx::BrushStyle,
                                                                exclude: ->(e) { e ==  Wx::BrushStyle::BRUSHSTYLE_INVALID }))
      @fill_szr.add(@fill_style, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(@fill_szr, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::ALL, 5))

      if Wx::SF::FilledArrow === arrow
        @fill_clr.colour = arrow.fill.colour
        @fill_style.selection = get_style_index(arrow.fill.style,
                                                exclude: ->(e) { e ==  Wx::BrushStyle::BRUSHSTYLE_INVALID })
      else
        @fill_szr.static_box.enable(false)
      end

      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::Button.new(self, Wx::ID_OK, "&Ok"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::Button.new(self, Wx::ID_CANCEL, "&Cancel"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::RIGHT, 80))

      set_auto_layout(true)
      set_sizer(sizer_top)

      sizer_top.set_size_hints(self)
      sizer_top.fit(self)

      evt_combobox @arrow, :on_arrow_type
      evt_radiobutton Wx::ID_ANY, :on_radiobutton
    end

    def get_arrow
      case @arrow.get_value
      when 'None'
        nil
      when 'Open', 'Cup', 'Prong', 'Crossbar', 'DoubleCrossbar'
        arrow = case @arrow.get_value
                when 'Open' then Wx::SF::OpenArrow.new
                when 'Prong' then Wx::SF::ProngArrow.new
                when 'Cup' then Wx::SF::CupArrow.new
                when 'Crossbar' then Wx::SF::CrossBarArrow.new
                when 'DoubleCrossbar' then Wx::SF::DoubleCrossBarArrow.new
                end
        if @custom_pen_rb.value
          arrow.set_pen(Wx::Pen.new(@line_clr.colour, @line_wdt.value,
                                    index_to_style(Wx::PenStyle, @line_style.selection,
                                                   exclude: ->(e) { e == Wx::PenStyle::PENSTYLE_INVALID })))
        end
        arrow
      else
        arrow_klass = case @arrow.get_value
                      when 'Solid' then Wx::SF::SolidArrow
                      when 'Diamond' then Wx::SF::DiamondArrow
                      when 'Circle' then Wx::SF::CircleArrow
                      when 'Square' then Wx::SF::SquareArrow
                      end
        arrow = arrow_klass.new
        if @custom_pen_rb.value
          arrow.set_pen(Wx::Pen.new(@line_clr.colour, @line_wdt.value,
                                    index_to_style(Wx::PenStyle, @line_style.selection,
                                                   exclude: ->(e) { e == Wx::PenStyle::PENSTYLE_INVALID })))
        end
        arrow.set_fill(Wx::Brush.new(@fill_clr.colour,
                                     index_to_style(Wx::BrushStyle, @fill_style.selection,
                                                    exclude: ->(e) { e == Wx::BrushStyle::BRUSHSTYLE_INVALID })))
        arrow
      end
    end

    def arrow_type(arrow)
      case arrow
      when Wx::SF::ProngArrow then 'Prong'
      when Wx::SF::OpenArrow then 'Open'
      when Wx::SF::CupArrow then 'Cup'
      when Wx::SF::DoubleCrossBarArrow then 'DoubleCrossbar'
      when Wx::SF::CrossBarArrow then 'Crossbar'
      when Wx::SF::DiamondArrow then 'Diamond'
      when Wx::SF::SquareArrow then 'Square'
      when Wx::SF::SolidArrow then 'Solid'
      when Wx::SF::CircleArrow then 'Circle'
      else
        'None'
      end
    end
    private :arrow_type

    def get_style_choices(enum, exclude: nil)
      FrameCanvas.get_style_choices(enum, exclude: exclude)
    end
    private :get_style_choices

    def get_style_index(enumerator, exclude: nil)
      FrameCanvas.get_style_index(enumerator, exclude: exclude)
    end
    private :get_style_index

    def index_to_style(enum, index, exclude: nil)
      FrameCanvas.index_to_style(enum, index, exclude: exclude)
    end
    private :index_to_style

    def on_radiobutton(_evt)
      if @line_pen_rb.value
        @line_clr.enable(false)
        @line_wdt.enable(false)
        @line_style.enable(false)
      else
        @line_clr.enable(true)
        @line_wdt.enable(true)
        @line_style.enable(true)
      end
    end
    private :on_radiobutton

    def on_arrow_type(_evt)
      case @arrow.get_value
      when 'None'
        @line_szr.static_box.enable(false)
        @fill_szr.static_box.enable(false)
      else
        @line_szr.static_box.enable(true)
        @line_pen_rb.value = true
        @line_clr.enable(false)
        @line_style.enable(false)
        @line_wdt.enable(false)
        case @arrow.get_value
        when 'Open', 'Prong', 'Cup', 'Crossbar', 'DoubleCrossbar'
          @fill_szr.static_box.enable(false)
        else
          @fill_szr.static_box.enable(true)
        end
      end
    end
    protected :get_style_choices

  end

  def on_right_down(event)
    # try to find shape under cursor
    shape = get_shape_under_cursor
    # alternatively you can use:
    # shape = get_shape_at_position(dp2lp(event.getposition), 1, SEARCHMODE::BOTH)

    # show shape popup (if found)
    if shape
      case self.get_popup_menu_selection_from_user(get_shape_popup(shape))
      when POPUP_ID::STYLE
        choices = get_style_choices(Wx::SF::Shape::STYLE,
                                    exclude: ->(e) { e ==  Wx::SF::Shape::STYLE::DEFAULT_SHAPE_STYLE })
        choices.pop # remove default style mask
        sel = Wx.get_selected_choices('Select styles',
                                      'Select multiple',
                                      choices,
                                      self,
                                      initial_selections: style_to_selections(Wx::SF::Shape::STYLE, shape.get_style,
                                                                              exclude: ->(e) { e ==  Wx::SF::Shape::STYLE::DEFAULT_SHAPE_STYLE }))
        if sel
          shape.set_style(selections_to_style(Wx::SF::Shape::STYLE, sel,
                                              exclude: ->(e) { e ==  Wx::SF::Shape::STYLE::DEFAULT_SHAPE_STYLE }))
          shape.update
        end
      when POPUP_ID::HOVER_COLOR
        color = Wx.get_colour_from_user(self, shape.get_hover_colour, 'Select hover colour')
        if color.ok?
          shape.set_hover_colour(color)
          shape.update
        end
      when POPUP_ID::HALIGN
        case Wx.get_single_choice('Select horizontal alignment',
                                  'Select',
                                  %w[NONE LEFT CENTER RIGHT EXPAND],
                                  self,
                                  initial_selection: shape.get_h_align.to_i)
        when 'NONE' then shape.set_h_align(Wx::SF::Shape::HALIGN::NONE)
        when 'LEFT' then shape.set_h_align(Wx::SF::Shape::HALIGN::LEFT)
        when 'CENTER' then shape.set_h_align(Wx::SF::Shape::HALIGN::CENTER)
        when 'RIGHT' then shape.set_h_align(Wx::SF::Shape::HALIGN::RIGHT)
        when 'EXPAND' then shape.set_h_align(Wx::SF::Shape::HALIGN::EXPAND)
        end
      when POPUP_ID::VALIGN
        case Wx.get_single_choice('Select vertical alignment',
                                  'Select',
                                  %w[NONE TOP MIDDLE BOTTOM EXPAND],
                                  self,
                                  initial_selection: shape.get_v_align.to_i)
        when 'NONE' then shape.set_v_align(Wx::SF::Shape::VALIGN::NONE)
        when 'TOP' then shape.set_v_align(Wx::SF::Shape::VALIGN::TOP)
        when 'MIDDLE' then shape.set_v_align(Wx::SF::Shape::VALIGN::MIDDLE)
        when 'BOTTOM' then shape.set_v_align(Wx::SF::Shape::VALIGN::BOTTOM)
        when 'EXPAND' then shape.set_v_align(Wx::SF::Shape::HALIGN::EXPAND)
        end
        shape.update
      when POPUP_ID::HBORDER
        FrameCanvas.FloatDialog(self, 'Enter horizontal margin', value: shape.get_h_border) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.set_h_border(dlg.get_value)
            shape.update
          end
        end
      when POPUP_ID::VBORDER
        FrameCanvas.FloatDialog(self, 'Enter vertical margin', value: shape.get_v_border) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.set_v_border(dlg.get_value)
            shape.update
          end
        end
      when POPUP_ID::FILL_COLOR
        color = Wx.get_colour_from_user(self, shape.get_fill.colour, 'Select fill colour')
        if color.ok?
          shape.set_fill(Wx::Brush.new(color, shape.get_fill.style))
          shape.update
        end
      when POPUP_ID::FILL_STYLE
        style_ix = Wx.get_single_choice_index('Select fill style',
                                              'Select',
                                              get_style_choices(Wx::BrushStyle,
                                                                exclude: ->(e) { e ==  Wx::BrushStyle::BRUSHSTYLE_INVALID }),
                                              self,
                                              initial_selection: get_style_index(shape.get_fill.style,
                                                                                 exclude: ->(e) { e ==  Wx::BrushStyle::BRUSHSTYLE_INVALID }))
        if style_ix >= 0
          shape.set_fill(Wx::Brush.new(shape.get_fill.colour,
                                       index_to_style(Wx::BrushStyle, style_ix,
                                                      exclude: ->(e) { e ==  Wx::BrushStyle::BRUSHSTYLE_INVALID })))
        end
      when POPUP_ID::BORDER_COLOR
        color = Wx.get_colour_from_user(self, shape.get_border.get_colour, 'Select border colour')
        if color.ok?
          border_pen =  shape.get_border
          shape.set_border(Wx::Pen.new(color, border_pen.width, border_pen.style))
          shape.update
        end
      when POPUP_ID::BORDER_STYLE
        style_ix = Wx.get_single_choice_index('Select border style',
                                              'Select',
                                              get_style_choices(Wx::PenStyle,
                                                                exclude: ->(e) { e ==  Wx::PenStyle::PENSTYLE_INVALID }),
                                              self,
                                              initial_selection: get_style_index(shape.get_border.style,
                                                                                 exclude: ->(e) { e ==  Wx::PenStyle::PENSTYLE_INVALID }))
        if style_ix >= 0
          shape.set_border(Wx::Pen.new(shape.get_border.colour,
                                       shape.get_border.width,
                                       index_to_style(Wx::PenStyle, style_ix,
                                                      exclude: ->(e) { e ==  Wx::PenStyle::PENSTYLE_INVALID })))
        end
      when POPUP_ID::BORDER_WIDTH
        wdt = Wx.get_number_from_user('Enter border width:', '', 'Border width', shape.border.width, 0, 100, self)
        if wdt >= 0
          border_pen =  shape.get_border
          shape.set_border(Wx::Pen.new(border_pen.colour, wdt, border_pen.style))
        end
      when POPUP_ID::LINE_COLOR
        color = Wx.get_colour_from_user(self, shape.line_pen.get_colour, 'Select line colour')
        if color.ok?
          line_pen =  shape.get_line_pen
          shape.set_line_pen(Wx::Pen.new(color, line_pen.width, line_pen.style))
          shape.update
        end
      when POPUP_ID::LINE_STYLE
        style_ix = Wx.get_single_choice_index('Select line style',
                                              'Select',
                                              get_style_choices(Wx::PenStyle,
                                                                exclude: ->(e) { e ==  Wx::PenStyle::PENSTYLE_INVALID }),
                                              self,
                                              initial_selection: get_style_index(shape.get_line_pen.style,
                                                                                 exclude: ->(e) { e ==  Wx::PenStyle::PENSTYLE_INVALID }))
        if style_ix >= 0
          shape.set_line_pen(Wx::Pen.new(shape.get_line_pen.colour,
                                         shape.get_line_pen.width,
                                         index_to_style(Wx::PenStyle, style_ix,
                                                        exclude: ->(e) { e == Wx::PenStyle::PENSTYLE_INVALID })))
        end
      when POPUP_ID::LINE_WIDTH
        wdt = Wx.get_number_from_user('Enter line width:', '', 'Line width', shape.line_pen.width, 0, 100, self)
        if wdt >= 0
          line_pen =  shape.get_line_pen
          shape.set_line_pen(Wx::Pen.new(line_pen.colour, wdt, line_pen.style))
        end
      when POPUP_ID::SRC_ARROW
        FrameCanvas.ArrowDialog(self, 'Source arrow', shape.get_src_arrow) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.src_arrow = dlg.get_arrow
            shape.update
          end
        end
      when POPUP_ID::TRG_ARROW
        FrameCanvas.ArrowDialog(self, 'Target arrow', shape.get_trg_arrow) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.trg_arrow = dlg.get_arrow
            shape.update
          end
        end
      when POPUP_ID::DUMP
        # show basic info
        msg = "Class name: #{shape.class}, ID: #{shape.object_id}\n"

        msg << "\nBounding box: #{shape.get_bounding_box.inspect}\n"

        # show parent (if any)
        if shape.parent_shape
          msg << "\nParent: #{shape.parent_shape.class}, ID: #{shape.parent_shape.object_id}\n"
        end

        # show info about shape's children
        lst_shapes = shape.get_child_shapes(nil, Wx::SF::RECURSIVE)
        unless lst_shapes.empty?
          msg << "\nChildren:\n"
          lst_shapes.each_with_index do |child, i|
            msg << "#{i+1}. Class name: #{child.class}, ID: #{child.object_id}\n"
          end
        end

        # show info about shape's neighbours
        lst_shapes = shape.get_neighbours(Wx::SF::LineShape, Wx::SF::Shape::CONNECTMODE::BOTH, Wx::SF::INDIRECT)
        unless lst_shapes.empty?
          msg << "\nNeighbours:\n"
          lst_shapes.each_with_index do |nbr, i|
            msg << "#{i+1}. Class name: #{nbr.class}, ID: #{nbr.object_id}\n"
          end
        end

        # show message
        Wx.message_box(msg, 'wxRuby ShapeFramework', Wx::OK | Wx::ICON_INFORMATION)
      end
    else
      Wx.message_box('No shape found on this position.', 'wxRuby ShapeFramework', Wx::OK | Wx::ICON_INFORMATION)
    end

    # call default handler
    super
  end

  def on_key_down(event)
    if event.get_key_code == Wx::K_ESCAPE
      @parent_frame.tool_mode = MainFrame::MODE::DESIGN
    end

    # do default actions
    super
  end

  def on_connection_finished(connection)
    if connection
		  # the line's ending style can be set like this:
      connection.set_trg_arrow(Wx::SF::SolidArrow)
      # also Wx::SF::OpenArrow, Wx::SF::DiamondArrow and Wx::SF::CircleArrow styles are available.
		  connection.set_src_arrow(Wx::SF::CircleArrow)
		
      connection.accept_child(Wx::SF::TextShape)
      connection.accept_child(Wx::SF::EditTextShape)

      connection.accept_connection(Wx::SF::ACCEPT_ALL)
      connection.accept_src_neighbour(Wx::SF::ACCEPT_ALL)
      connection.accept_trg_neighbour(Wx::SF::ACCEPT_ALL)
		
		  connection.set_dock_point(Wx::SF::LineShape::DEFAULT::DOCKPOINT_CENTER)

      @parent_frame.tool_mode = MainFrame::MODE::DESIGN
    end
  end

  def on_mouse_wheel(event)
    # do default actions
    super
  
    # adjust zoom slider control
    @parent_frame.zoom_slider.set_value((get_scale * 50).to_i)
  end

end
