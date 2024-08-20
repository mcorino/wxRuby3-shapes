# Wx::SF - Demo FrameCanvas
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes'

class FrameCanvas < Wx::SF::ShapeCanvas

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

  def on_right_down(event)
    # try to find shape under cursor
    shape = get_shape_under_cursor
    # alternatively you can use:
    # shape = get_shape_at_position(dp2lp(event.getposition), 1, SEARCHMODE::BOTH)

    # print out information about the shape (if found)
    if shape
      # show basic info
      msg = "Class name: #{shape.class}, ID: #{shape.get_id}\n"

      # show info about shape's children
      lst_shapes = shape.get_child_shapes(nil, Wx::SF::RECURSIVE)
      unless lst_shapes.empty?
        msg << "\nChildren:\n"
        lst_shapes.each_with_index do |child, i|
            msg << "#{i+1}. Class name: #{child.class}, ID: #{child.get_id}\n"
        end
      end

      # show info about shape's neighbours
      lst_shapes = shape.get_neighbours(Wx::SF::LineShape, Wx::SF::Shape::CONNECTMODE::BOTH, Wx::SF::INDIRECT)
      unless lst_shapes.empty?
        msg << "\nNeighbours:\n"
        lst_shapes.each_with_index do |nbr, i|
          msg << "#{i+1}. Class name: #{nbr.class}, ID: #{nbr.get_id}\n"
        end
      end

      # show message
      Wx.message_box(msg, 'wxRuby ShapeFramework', Wx::OK | Wx::ICON_INFORMATION)
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
