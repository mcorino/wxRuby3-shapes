# Wx::SF - Demo FrameCanvas
# Copyright (c) M.J.N. Corino, The Netherlands

require_relative './dialogs'

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
    ACCEPTED = self.next_id
    ACC_CHILDREN = self.next_id
    ACC_CONNECTIONS = self.next_id
    ACC_CONNECTION_FROM = self.next_id
    ACC_CONNECTION_TO = self.next_id
    CONNECTION_POINTS = self.next_id

    # rect
    FILL_BRUSH = self.next_id
    BORDER_PEN = self.next_id

    # line
    LINE_PEN = self.next_id
    LINE_ARROWS = self.next_id
    SRC_ARROW = self.next_id
    TRG_ARROW = self.next_id

    # text
    TEXT_FONT = self.next_id
    TEXT_COLOR = self.next_id

    # box
    BOX_SPACING = self.next_id

    # grid
    GRID_SETTINGS = self.next_id
    GRID_SPACING = self.next_id
    GRID_MAXROWS = self.next_id

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
        shape.accept_child(Wx::SF::RectShape)
        shape.accept_child(Wx::SF::VBoxShape)

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

        # number of rows and columns cas be set here (default grid dimension is 3x1) ...
        shape.set_dimensions(2, @parent_frame.grid_columns)

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
      _, shape = get_diagram.insert_shape(Wx::SF::LineShape.new((event.get_position - [50, 0]).to_real,
                                                                (event.get_position + [50, 0]).to_real),
                                          event.get_position,
                                          Wx::SF::DONT_SAVE_STATE)
      if shape
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

  def create_shape_popup
    menu = Wx::Menu.new
    menu.append(POPUP_ID::STYLE, 'Change style', 'Change style')
    menu.append(POPUP_ID::HOVER_COLOR, 'Change hover colour', 'Change hover colour')
    menu.append(POPUP_ID::HALIGN, 'Change horizontal alignment', 'Change horizontal alignment')
    menu.append(POPUP_ID::VALIGN, 'Change vertical alignment', 'Change vertical alignment')
    menu.append(POPUP_ID::HBORDER, 'Change horizontal margin', 'Change horizontal margin')
    menu.append(POPUP_ID::VBORDER, 'Change vertical margin', 'Change vertical margin')
    submenu = Wx::Menu.new
    submenu.append(POPUP_ID::ACC_CHILDREN, 'Child shapes', 'Change accepted child shapes')
    submenu.append(POPUP_ID::ACC_CONNECTIONS, 'Connections', 'Change accepted connections')
    submenu.append(POPUP_ID::ACC_CONNECTION_FROM, 'Connection sources', 'Change accepted connection sources')
    submenu.append(POPUP_ID::ACC_CONNECTION_TO, 'Connection targets', 'Change accepted connection targets')
    menu.append(Wx::MenuItem.new(submenu, POPUP_ID::ACCEPTED, 'Change accepted', '', Wx::ItemKind::ITEM_NORMAL, submenu))
    menu.append(POPUP_ID::CONNECTION_POINTS, 'Change connection points', 'Change connection points')

    @rect_mi = []
    @rect_mi << Wx::MenuItem.new(menu, POPUP_ID::FILL_BRUSH, 'Change fill', 'Change fill brush')
    @rect_mi << Wx::MenuItem.new(menu, POPUP_ID::BORDER_PEN, 'Change border', 'Change border pen')

    @line_mi = []
    @line_mi << Wx::MenuItem.new(menu, POPUP_ID::LINE_PEN, 'Change line', 'Change line pen')
    submenu = Wx::Menu.new
    submenu.append(POPUP_ID::SRC_ARROW, 'Change source arrow', 'Change source arrow')
    submenu.append(POPUP_ID::TRG_ARROW, 'Change target arrow', 'Change target arrow')
    @line_mi << Wx::MenuItem.new(menu, POPUP_ID::LINE_ARROWS, 'Change arrows', '', Wx::ItemKind::ITEM_NORMAL, submenu)

    @text_mi = []
    @text_mi << Wx::MenuItem.new(menu, POPUP_ID::TEXT_FONT, 'Change text font', 'Change text font')
    @text_mi << Wx::MenuItem.new(menu, POPUP_ID::TEXT_COLOR, 'Change text colour', 'Change text colour')

    @box_mi = Wx::MenuItem.new(menu, POPUP_ID::BOX_SPACING, 'Change slot spacing', 'Change slot spacing')

    submenu = Wx::Menu.new
    submenu.append(POPUP_ID::GRID_SPACING, 'Change cell spacing', 'Change cell spacing')
    submenu.append(POPUP_ID::GRID_MAXROWS, 'Change row maximum', 'Change row maximum')
    @grid_mi = Wx::MenuItem.new(menu, POPUP_ID::GRID_SETTINGS, 'Change grid settings', 'Change grid settings', Wx::ItemKind::ITEM_NORMAL, submenu)

    menu.append_separator
    menu.append(POPUP_ID::DUMP, 'Show serialized state', 'Show serialized state')
    menu
  end
  private :create_shape_popup

  def remove_popup_items(*item_ids)
    item_ids.flatten.each { |id| @popup.remove(id) if @popup.find_item(id) }
  end
  private :remove_popup_items

  def get_shape_popup(shape)
    @popup ||= create_shape_popup
    case shape
    when Wx::SF::RectShape
      remove_popup_items(POPUP_ID::LINE_PEN, POPUP_ID::LINE_ARROWS)
      n = @popup.get_menu_item_count-2
      @rect_mi.reverse.each { |mi| @popup.insert(n, mi) unless  @popup.find_item(mi.id) }
      case shape
      when Wx::SF::TextShape
        remove_popup_items(POPUP_ID::BOX_SPACING, POPUP_ID::GRID_SETTINGS)
        n = @popup.get_menu_item_count-2
        @text_mi.reverse.each { |mi| @popup.insert(n, mi) unless  @popup.find_item(mi.id) }
      when Wx::SF::BoxShape
        remove_popup_items(POPUP_ID::TEXT_FONT, POPUP_ID::TEXT_COLOR, POPUP_ID::GRID_SETTINGS)
        n = @popup.get_menu_item_count-2
        @popup.insert(n, @box_mi) unless  @popup.find_item(@box_mi.id)
      when Wx::SF::GridShape
        remove_popup_items(POPUP_ID::TEXT_FONT, POPUP_ID::TEXT_COLOR, POPUP_ID::BOX_SPACING)
        n = @popup.get_menu_item_count-2
        @popup.insert(n, @grid_mi) unless  @popup.find_item(@grid_mi.id)
      else
        remove_popup_items(POPUP_ID::TEXT_FONT, POPUP_ID::TEXT_COLOR, POPUP_ID::BOX_SPACING, POPUP_ID::GRID_SETTINGS)
      end
    when Wx::SF::LineShape
      remove_popup_items(POPUP_ID::FILL_BRUSH, POPUP_ID::BORDER_PEN,
                         POPUP_ID::TEXT_FONT, POPUP_ID::TEXT_COLOR,
                         POPUP_ID::BOX_SPACING, POPUP_ID::GRID_SETTINGS)
      n = @popup.get_menu_item_count-2
      @line_mi.reverse.each { |mi| @popup.insert(n, mi) unless @popup.find_item(mi.id) }
    else
      remove_popup_items(POPUP_ID::FILL_BRUSH, POPUP_ID::BORDER_PEN,
                         POPUP_ID::LINE_PEN, POPUP_ID::LINE_ARROWS,
                         POPUP_ID::TEXT_FONT, POPUP_ID::TEXT_COLOR,
                         POPUP_ID::BOX_SPACING, POPUP_ID::GRID_SETTINGS)
    end
    @popup
  end
  private :get_shape_popup

  def get_enum_choices(enum, excludes: nil)
    Dialogs.get_enum_choices(enum, excludes: excludes)
  end

  def get_enum_index(enumerator, excludes: nil)
    Dialogs.get_enum_index(enumerator, excludes: excludes)
  end

  def index_to_enum(enum, index, excludes: nil)
    Dialogs.index_to_enum(enum, index, excludes: excludes)
  end

  def selections_to_enum(enum, selections, excludes: nil)
    Dialogs.selections_to_enum(enum, selections, excludes: excludes)
  end

  def enum_to_selections(enum, style, excludes: nil)
    Dialogs.enum_to_selections(enum, style, excludes: excludes)
  end

  SHAPES = [
    Wx::SF::RectShape,
    Wx::SF::BitmapShape,
    Wx::SF::SquareShape,
    Wx::SF::CircleShape,
    Wx::SF::PolygonShape,
    Wx::SF::TextShape,
    Wx::SF::RoundRectShape,
    Wx::SF::GridShape,
    Wx::SF::FlexGridShape,
    Wx::SF::EllipseShape,
    Wx::SF::ControlShape,
    Wx::SF::BoxShape,
    Wx::SF::VBoxShape,
    Wx::SF::HBoxShape,
    Wx::SF::DiamondShape,
    Wx::SF::EditTextShape
  ]

  CONNECTION_SHAPES = [
    Wx::SF::LineShape,
    Wx::SF::CurveShape,
    Wx::SF::OrthoLineShape,
    Wx::SF::RoundOrthoLineShape
  ]

  def on_right_down(event)
    # try to find shape under cursor
    shape = get_shape_under_cursor
    # alternatively you can use:
    # shape = get_shape_at_position(dp2lp(event.getposition), 1, SEARCHMODE::BOTH)

    # show shape popup (if found)
    if shape
      case self.get_popup_menu_selection_from_user(get_shape_popup(shape))
      when POPUP_ID::STYLE
        choices = get_enum_choices(Wx::SF::Shape::STYLE,
                                   excludes: %i[DEFAULT_SHAPE_STYLE PROPAGATE_ALL])
        sel = Wx.get_selected_choices('Select styles',
                                      'Select multiple',
                                      choices,
                                      self,
                                      initial_selections: enum_to_selections(Wx::SF::Shape::STYLE, shape.get_style,
                                                                             excludes: %i[DEFAULT_SHAPE_STYLE PROPAGATE_ALL]))
        if sel
          shape.set_style(selections_to_enum(Wx::SF::Shape::STYLE, sel,
                                             excludes: %i[DEFAULT_SHAPE_STYLE PROPAGATE_ALL]))
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
        shape.update
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
        Dialogs.FloatDialog(self, 'Enter horizontal margin', value: shape.get_h_border) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.set_h_border(dlg.get_value)
            shape.update
          end
        end
      when POPUP_ID::VBORDER
        Dialogs.FloatDialog(self, 'Enter vertical margin', value: shape.get_v_border) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.set_v_border(dlg.get_value)
            shape.update
          end
        end
      when POPUP_ID::ACC_CHILDREN
        Dialogs.AcceptedShapesDialog(self, 'Select acceptable child shapes.', SHAPES, shape.accepted_children) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.accepted_children.clear
            if (ss = dlg.get_selected_shapes(SHAPES))
              shape.accepted_children.merge(ss)
            end
          end
        end
      when POPUP_ID::ACC_CONNECTIONS
        Dialogs.AcceptedShapesDialog(self, 'Select acceptable connection shapes.', CONNECTION_SHAPES, shape.accepted_connections) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.accepted_connections.clear
            if (ss = dlg.get_selected_shapes(CONNECTION_SHAPES))
              shape.accepted_connections.merge(ss)
            end
          end
        end
      when POPUP_ID::ACC_CONNECTION_FROM
        shape_options =  SHAPES - [shape.class]
        Dialogs.AcceptedShapesDialog(self, 'Select acceptable connection source shapes.', shape_options, shape.accepted_src_neighbours) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.accepted_src_neighbours.clear
            if (ss = dlg.get_selected_shapes(shape_options))
              shape.accepted_src_neighbours.merge(ss)
            end
          end
        end
      when POPUP_ID::ACC_CONNECTION_TO
        shape_options =  SHAPES - [shape.class]
        Dialogs.AcceptedShapesDialog(self, 'Select acceptable connection target shapes.', shape_options, shape.accepted_trg_neighbours) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.accepted_trg_neighbours.clear
            if (ss = dlg.get_selected_shapes(shape_options))
              shape.accepted_trg_neighbours.merge(ss)
            end
          end
        end
      when POPUP_ID::CONNECTION_POINTS
        Dialogs.ConnectionPointDialog(self, shape.connection_points) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            dlg.set_shape_connection_points(shape)
            shape.update
          end
        end
      when POPUP_ID::FILL_BRUSH
        Dialogs.BrushDialog(self, 'Fill brush', shape.fill) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.set_fill(dlg.get_brush)
            shape.update
          end
        end
      when POPUP_ID::BORDER_PEN
        Dialogs.PenDialog(self, 'Border pen', shape.border) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.set_border(dlg.get_pen)
            shape.update
          end
        end
      when POPUP_ID::TEXT_FONT
        new_font = Wx.get_font_from_user(self, shape.font, 'Select text font')
        if new_font.ok?
          shape.font = new_font
          shape.update
        end
      when POPUP_ID::TEXT_COLOR
        color = Wx.get_colour_from_user(self, shape.text_colour, 'Select text colour')
        if color.ok?
          shape.text_colour(color)
          shape.update
        end
      when POPUP_ID::BOX_SPACING
        spc = Wx.get_number_from_user('Enter BoxShape slot spacing.', 'Value:', 'Slot spacing',
                                shape.spacing, 0, 100, self)
        if spc >= 0
          shape.spacing = spc
          shape.update
        end
      when POPUP_ID::GRID_SPACING
        spc = Wx.get_number_from_user('Enter GridShape cell spacing.', 'Value:', 'Cell spacing',
                                      shape.cell_space, 0, 100, self)
        if spc >= 0
          shape.cell_space = spc
          shape.update
        end
      when POPUP_ID::GRID_MAXROWS
        spc = Wx.get_number_from_user('Enter GridShape maximum rows.', 'Value:', 'Maximum rows',
                                      shape.max_rows, 0, 100, self)
        if spc >= 0
          shape.max_rows = spc
          shape.update
        end
      when POPUP_ID::LINE_PEN
        Dialogs.PenDialog(self, 'Line pen', shape.line_pen) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.set_line_pen(dlg.get_pen)
            shape.update
          end
        end
      when POPUP_ID::SRC_ARROW
        Dialogs.ArrowDialog(self, 'Source arrow', shape.get_src_arrow) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.src_arrow = dlg.get_arrow
            shape.update
          end
        end
      when POPUP_ID::TRG_ARROW
        Dialogs.ArrowDialog(self, 'Target arrow', shape.get_trg_arrow) do |dlg|
          if dlg.show_modal == Wx::ID_OK
            shape.trg_arrow = dlg.get_arrow
            shape.update
          end
        end
      when POPUP_ID::DUMP
        Dialogs.StateDialog(self, shape)
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
