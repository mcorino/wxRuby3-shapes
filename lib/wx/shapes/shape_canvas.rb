# Wx::SF::ShapeCanvas - shape canvas class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shape_data_object'

module Wx::SF

  DEFAULT_ME_OFFSET = 5
  SAVE_STATE = true
  DONT_SAVE_STATE = false
  FROM_PAINT = true
  NOT_FROM_PAINT = false
  TOPMOST_SHAPES = true
  ALL_SHAPES = false
  PROMPT = true
  NO_PROMPT = false
  WITH_BACKGROUND = true
  WITHOUT_BACKGROUND = false

  if Wx.has_feature?(:USE_DRAG_AND_DROP)

    # Auxiliary class encapsulating shape drop target.
    class CanvasDropTarget < Wx::DropTarget

      # @param [Wx::DataObject] data
      # @param [Wx::SF::ShapeCanvas] parent
      def initialize(data, parent)
        super(data)
        @parent_canvas = parent
      end

      # @param [Integer] x
      # @param [Integer] y
      # @param [Wx::DragResult] deflt
      # @return [Wx::DragResult]
      def on_data(x, y, deflt)
        return Wx::DragResult::DragNone unless get_data

        @parent_canvas.__send__(:_on_drop, x, y, deflt, get_data_object)
        return deflt
      end

    end
  end

  # Class encapsulating a Shape canvas. The shape canvas is window control
  # which extends the Wx::ScrolledWindow and is responsible for displaying of shapes diagrams.
  # It also supports clipboard and drag&drop operations, undo/redo operations,
  # and graphics exporting functions.
  #
  # This class is a core framework class and provides many member functions suitable for adding,
  # removing, moving, resizing and drawing of shape objects. It can be used as it is or as a base class
  # if necessary. In that case, the default class functionality can be enhanced by overriding
  # its methods or by manual events handling. In both cases the user is responsible
  # for invoking of default event handlers/virtual functions otherwise the
  # built in functionality wont be available.
  # @see Wx::SF::Diagram
  class ShapeCanvas < Wx::ScrolledWindow

    # Working modes 
    class MODE < Wx::Enum
      # The shape canvas is in ready state (no operation is pending)
      READY = self.new(0)
      # Some shape handle is dragged
      HANDLEMOVE = self.new(1)
      # Handle of multiselection tool is dragged
      MULTIHANDLEMOVE = self.new(2)
      # Some shape/s is/are dragged
      SHAPEMOVE = self.new(3)
      # Multiple shape selection is in progress
      MULTISELECTION = self.new(4)
      # Interactive connection creation is in progress
      CREATECONNECTION = self.new(5)
      # Canvas is in the Drag&Drop mode
      DND = self.new(6)
    end

    # Selection modes
    class SELECTIONMODE < Wx::Enum
      NORMAL = self.new(0)
      ADD = self.new(1)
      REMOVE = self.new(2)
    end

    # Search mode flags for GetShapeAtPosition function
    class SEARCHMODE < Wx::Enum
      # Search for selected shapes only
      SELECTED = self.new(0)
      # Search for unselected shapes only
      UNSELECTED = self.new(1)
      # Search for both selected and unselected shapes
      BOTH = self.new(2)
    end

    # Flags for AlignSelected function
    class VALIGN < Wx::Enum
      NONE = self.new(0)
      TOP = self.new(1)
      MIDDLE = self.new(2)
      BOTTOM = self.new(3)
    end

    # Flags for AlignSelected function
    class HALIGN < Wx::Enum
      NONE = self.new(0)
      LEFT = self.new(1)
      CENTER = self.new(2)
      RIGHT = self.new(3)
    end

    # Style flags
    class STYLE < Wx::Enum
      # Allow multiselection box.
      MULTI_SELECTION = self.new(1)
      # Allow shapes' size change done via the multiselection box.
      MULTI_SIZE_CHANGE = self.new(2)
      # Show grid.
      GRID_SHOW = self.new(4)
      # Use grid.
      GRID_USE = self.new(8)
      # Enable Drag & Drop operations.
      DND = self.new(16)
      # Enable Undo/Redo operations.
      UNDOREDO = self.new(32)
      # Enable the clipboard.
      CLIPBOARD = self.new(64)
      # Enable mouse hovering
      HOVERING = self.new(128)
      # Enable highlighting of shapes able to accept dragged shape(s).
      HIGHLIGHTING = self.new(256)
      # Use gradient color for the canvas background.
      GRADIENT_BACKGROUND = self.new(512)
      # Print also canvas background.
      PRINT_BACKGROUND = self.new(1024)
      # Process mouse wheel by the canvas (canvas scale will be changed).
      PROCESS_MOUSEWHEEL = self.new(2048)
      # Default canvas style.
      DEFAULT_CANVAS_STYLE = MULTI_SELECTION | MULTI_SIZE_CHANGE | DND | UNDOREDO | CLIPBOARD | HOVERING | HIGHLIGHTING
    end

    # Flags for ShowShadow function.
    class SHADOWMODE < Wx::Enum
      # Show/hide shadow under topmost shapes only.
      TOPMOST = self.new(0)
      # Show/hide shadow under all shapes in the diagram.
      ALL = self.new(1)
    end

    # Printing modes used by SetPrintMode() function.
    class PRINTMODE < Wx::Enum
      # This sets the user scale and origin of the DC so that the image fits
      # within the paper rectangle (but the edges could be cut off by printers
      # that can't print to the edges of the paper -- which is most of them. Use
      # this if your image already has its own margins.
      FIT_TO_PAPER = self.new(0)
      # This sets the user scale and origin of the DC so that the image fits
      # within the page rectangle, which is the printable area on Mac and MSW
      # and is the entire page on other platforms.
      FIT_TO_PAGE = self.new(1)
      # This sets the user scale and origin of the DC so that the image fits
      # within the page margins as specified by g_PageSetupData, which you can
      # change (on some platforms, at least) in the Page Setup dialog. Note that
      # on Mac, the native Page Setup dialog doesn't let you change the margins
      # of a Wx::PageSetupDialogData object, so you'll have to write your own dialog or
      # use the Mac-only Wx::MacPageMarginsDialog, as we do in this program.
      FIT_TO_MARGINS = self.new(2)
      # This sets the user scale and origin of the DC so that you could map the
      # screen image to the entire paper at the same size as it appears on screen.
      MAP_TO_PAPER = self.new(3)
      # This sets the user scale and origin of the DC so that the image appears
      # on the paper at the same size that it appears on screen (i.e., 10-point
      # type on screen is 10-point on the printed page).
      MAP_TO_PAGE = self.new(4)
      # This sets the user scale and origin of the DC so that you could map the
      # screen image to the page margins specified by the native Page Setup dialog at the same
      # size as it appears on screen.
      MAP_TO_MARGINS = self.new(5)
      # This sets the user scale and origin of the DC so that you can to do you own
      # scaling in order to draw objects at full native device resolution.
      MAP_TO_DEVICE = self.new(6)
    end

    class PRECONNECTIONFINISHEDSTATE < Wx::Enum
      # Finish line connection.
      OK = self.new(0)
      # Cancel line connection and abort the interactive connection.
      FAILED_AND_CANCEL_LINE = self.new(1)
      # Cancel line connection and continue with the interactive connection.
      FAILED_AND_CONTINUE_EDIT = self.new(2)
    end

    # Default values
    # Note: GUI objects like colours, brushes, pens etc. need a running Wx::App
    #       before initializing so we use lambdas here to delay creation.
    module DEFAULT
      # Default value of Wx::SF::CanvasSettings @background_color data member
      SHAPECANVAS_BACKGROUNDCOLOR = ->() { Wx::Colour.new(240, 240, 240) }
      # Default value of Wx::SF::CanvasSettings @grid_size data member
      SHAPECANVAS_GRIDSIZE = Wx::Size.new(10, 10)
      # Default value of Wx::SF::CanvasSettings @grid_line_mult data member
      SHAPECANVAS_GRIDLINEMULT = 1
      # Default value of Wx::SF::CanvasSettings @grid_color data member
      SHAPECANVAS_GRIDCOLOR = ->() { Wx::Colour.new(200, 200, 200) }
      # Default value of Wx::SF::CanvasSettings @grid_style data member
      SHAPECANVAS_GRIDSTYLE = Wx::PenStyle::PENSTYLE_SOLID
      # Default value of Wx::SF::CanvasSettings @common_hover_color data member
      SHAPECANVAS_HOVERCOLOR = ->() { Wx::Colour.new(120, 120, 255) }
      # Default value of Wx::SF::CanvasSettings @gradient_from data member
      SHAPECANVAS_GRADIENT_FROM = ->() { Wx::Colour.new(240, 240, 240) }
      # Default value of Wx::SF::CanvasSettings @gradient_to data member
      SHAPECANVAS_GRADIENT_TO = ->() { Wx::Colour.new(200, 200, 255) }
      # Default value of Wx::SF::CanvasSettings @style data member
      SHAPECANVAS_STYLE = STYLE::DEFAULT_CANVAS_STYLE
      # Default value of Wx::SF::CanvasSettings @shadow_offset data member
      SHAPECANVAS_SHADOWOFFSET = Wx::RealPoint(4, 4)
      # Default shadow colour 
      SHAPECANVAS_SHADOWCOLOR = ->() { Wx::Colour.new(150, 150, 150, 128) }
      # Default value of Wx::SF::CanvasSettings @shadow_fill data member
      SHAPECANVAS_SHADOWBRUSH = ->() { Wx::Brush.new(SHAPECANVAS_SHADOWCOLOR.call, Wx::BrushStyle::BRUSHSTYLE_SOLID) }
      # Default value of Wx::SF::CanvasSettings @print_h_align data member
      SHAPECANVAS_PRINT_HALIGN = HALIGN::CENTER
      # Default value of Wx::SF::CanvasSettings @print_v_align data member
      SHAPECANVAS_PRINT_VALIGN = VALIGN::MIDDLE
      # Default value of Wx::SF::CanvasSettings @print_mode data member
      SHAPECANVAS_PRINT_MODE = PRINTMODE::FIT_TO_MARGINS
      # Default value of Wx::SF::CanvasSettings @min_scale data member
      SHAPECANVAS_SCALE_MIN = 0.1
      # Default value of Wx::SF::CanvasSettings @max_scale data member
      SHAPECANVAS_SCALE_MAX = 5.0
    end

    # Auxiliary serializable class encapsulating the canvas properties.
    class Settings

      include Serializable

      include DEFAULT

      property :scale, :min_scale, :max_scale, :background_color, :common_hover_color,
               :grid_size, :grid_line_mult, :grid_color, :grid_style,
               :gradient_from, :gradient_to, :style, :shadow_offset, :shadow_fill,
               :print_h_align, :print_v_align, :print_mode, :accepted_shapes

      def initialize
        @scale = 1.0
        @min_scale = SHAPECANVAS_SCALE_MIN
        @max_scale = SHAPECANVAS_SCALE_MAX
        @background_color = SHAPECANVAS_BACKGROUNDCOLOR.call
        @common_hover_color = SHAPECANVAS_HOVERCOLOR.call
        @grid_size = SHAPECANVAS_GRIDSIZE
        @grid_line_mult = SHAPECANVAS_GRIDLINEMULT
        @grid_color = SHAPECANVAS_GRIDCOLOR.call
        @grid_style = SHAPECANVAS_GRIDSTYLE
        @gradient_from = SHAPECANVAS_GRADIENT_FROM.call
        @gradient_to = SHAPECANVAS_GRADIENT_TO.call
        @style = SHAPECANVAS_STYLE
        @shadow_offset = SHAPECANVAS_SHADOWOFFSET
        @shadow_fill = SHAPECANVAS_SHADOWBRUSH.call
        @print_h_align = SHAPECANVAS_PRINT_HALIGN
        @print_v_align = SHAPECANVAS_PRINT_VALIGN
        @print_mode = SHAPECANVAS_PRINT_MODE
        @accepted_shapes = ::Set.new
      end

      attr_accessor :scale, :min_scale, :max_scale, :background_color, :common_hover_color,
                    :grid_size, :grid_line_mult, :grid_color, :grid_style,
                    :gradient_from, :gradient_to, :style, :shadow_offset, :shadow_fill,
                    :print_h_align, :print_v_align, :print_mode, :accepted_shapes

    end

    class << self

      def gc_enabled?
        @gc_enabled
      end

      def enable_gc(f = true)
        if Wx.has_feature?(:USE_GRAPHICS_CONTEXT)
          @gc_enabled = f
        else
          @gc_enabled = false
          Wx.log_warning(%Q{Couldn't enable Graphics context due to missing USE_GRAPHICS_CONTEXT})
        end
      end

    end

    # @overload initialize()
    #   Default constructor
    # @overload initialize(diagram, parent, id = Wx::ID_ANY, pos = Wx::DEFAULT_POSITION, size = Wx::DEFAULT_SIZE, style = Wx::HSCROLL | Wx::VSCROLL)
    #   Constructor
    #   @param [Wx::SF::Diagram] diagram shape diagram
    #   @param [Wx::Window] parent Parent window
    #   @param [Integer] id Window ID
    #   @param [Wx::Point] pos Initial position
    #   @param [Wx::Size] size Initial size
    #   @param [Integer] style Window style
    def initialize(diagram = nil, *mixed_args)
      if diagram
        parent = mixed_args.first.is_a?(Wx::Window) ? mixed_args.shift : nil
        begin
          real_args = [parent] + Wx::ScrolledWindow.args_as_list(*mixed_args)
          create(*real_args)
        rescue => err
          msg = "Error initializing #{self.inspect}\n" +
            " : #{err.message} \n" +
            "Provided are #{real_args} \n" +
            "Correct parameters for #{self.class.name}.new are:\n" +
            self.class.describe_constructor()

          new_err = err.class.new(msg)
          new_err.set_backtrace(caller)
          Kernel.raise new_err
        end

        self.diagram = diagram

        save_canvas_state
      else
        super()
      end
    end

    def create(parent, id = -1, pos = Wx::DEFAULT_POSITION, size = Wx::DEFAULT_SIZE, style = (Wx::HSCROLL | Wx::VSCROLL), name = "Wx::ScrolledWindow")
      # NOTE: user must call Wx::SF::ShapeCanvas::SetDiagramManager() to complete
      # canvas initialization!

      # perform basic window initialization
      super

      # set drop target
      if Wx.has_feature?(:USE_DRAG_AND_DROP)
        set_drop_target(Wx::SF::CanvasDropTarget.new(Wx::SF::ShapeDataObject.new, self))
      end
      @d_n_d_started_here = false

      # initialize data members
      @can_save_state_on_mouse_up = false

      @working_mode = MODE::READY
      @selection_mode = SELECTIONMODE::NORMAL
      @selected_handle = nil
      @new_line_shape = nil
      @unselected_shape_under_cursor = nil
      @selected_shape_under_cursor = nil
      @topmost_shape_under_cursor = nil

      # initialize selection rectangle
      @shp_selection = MultiSelRect.new
      @shp_selection.set_id(nil)
      @shp_selection.create_handles
      @shp_selection.select(true)
      @shp_selection.show(false)
      @shp_selection.show_handles(true)

      # initialize multi-edit rectangle
      @shp_multi_edit = MultiSelRect.new
      @shp_multi_edit.set_id(nil)
      @shp_multi_edit.create_handles
      @shp_multi_edit.select(true)
      @shp_multi_edit.show(false)
      @shp_multi_edit.show_handles(true)

      @canvas_history = CanvasHistory.new(self)

      # if ++m_nRefCounter == 1 )
      #   {
      #     // initialize printing
      #   InitializePrinting()
      #
      #   // initialize output bitmap
      #   int nWidth, nHeight;
      #   Wx::DisplaySize(&nWidth, &nHeight)
      #
      #   if( !m_OutBMP.Create(nWidth, nHeight) )
      #     {
      #       Wx::LogError(Wx::T("Couldn't create output bitmap."))
      #     }
      #     }
      #
      #     SetScrollbars(5, 5, 100, 100)
      #     SetBackgroundStyle(Wx::BG_STYLE_CUSTOM)
      #
      #     return true;
    end

    # Returns the shape diagram which shapes are displayed on this canvas.
    # @return [Wx::SF::Diagram]
    def get_diagram
      @diagram
    end

    alias :diagram :get_diagram

    # Set the shape diagram to display on this canvas
    # @param [Wx::SF::Diagram] diagram
    def set_diagram(diagram)
      @diagram = diagram
      @shp_selection.set_diagram(@diagram)
      @shp_multi_edit.set_diagram(@diagram)
      @diagram.shape_canvas = self if @diagram
    end

    alias :diagram= :set_diagram

    # Load serialized canvas content (diagrams) from given file.
    # @param [String] file Full file name
    def load_canvas(file) end

    # Save  canvas content (diagrams) to given file.
    # @param [String] file Full file name
    def save_canvas(file) end

    # Export canvas content to image file.
    # @param [String] file Full file name
    # @param [Wx::BitmapType] type Image type. See Wx::BitmapType for more details. Default type is
    #                              Wx::BITMAP_TYPE_BMP.
    # @param [Boolean] background Export also diagram background
    # @param [Float] scale Image scale. If -1 then current canvas scale id used.
    def save_canvas_to_image(file, type = Wx::BITMAP_TYPE_BMP, background = true, scale = -1.0) end

    # Start interactive connection creation.
    #
    # This function switches the canvas to a mode in which a new shape connection
    # can be created interactively (by mouse operations). Every connection must
    # start and finish in some shape object or another connection. At the end of the
    # process the on_connection_finished event handler is invoked so the user can
    # set needed connection properties immediately.
    #
    # Function must be called from mouse event handler and the event must be passed
    # to the function.
    # @overload start_interactive_connection(shape_info, pos)
    #   @param [Class] shape_info Connection type
    #   @param [Wx::Point] pos Position where to start
    #   @return [Wx::SF::ERRCODE] operation result
    # @overload start_interactive_connection(shape, pos)
    #   @param [Wx::SF::LineShape] shape existing line shape object which will be used as a connection.
    #   @param [Wx::Point] pos Position where to start
    #   @return [Wx::SF::ERRCODE] err operation result
    # @overload start_interactive_connection(shape, connection_point, pos)
    #   @param [Wx::SF::LineShape] shape existing line shape object which will be used as a connection.
    #   @param [Wx::SF::ConnectionPoint] connection_point Initial connection point
    #   @param [Wx::Point] pos Position where to start
    #   @return [Wx::SF::ERRCODE] err operation result
    # @see create_connection
    def start_interactive_connection(*args) end

    # Abort interactive connection creation process
    def abort_interactive_connection

    end

    # Select all shapes in the canvas
    def select_all

    end

    # Deselect all shapes
    def deselect_all

    end

    # Hide handles of all shapes
    def hide_all_handles

    end

    # Repaint the shape canvas.
    # @param [Boolean] erase true if the canvas should be erased before repainting
    # @param [Wx::Rect] rct Refreshed region (rectangle)
    def refresh_canvas(erase, rct) end

    # Mark given rectangle as an invalidated one, i.e. as a rectangle which should
    # be refreshed (by using Wx::SF::ShapeCanvas::refresh_invalidated_rect).
    # @param [Wx::Rect] rct Rectangle to be invalidated
    def invalidate_rect(rct) end

    # Mark whole visible canvas portion as an invalidated rectangle.
    def invalidate_visible_rect

    end

    # Refresh all canvas rectangles marked as invalidated.
    # @see Wx::SF::ShapeCanvas::invalidate_rect
    def refresh_invalidated_rect

    end

    # Show shapes shadows (only current diagram shapes are affected).
    #
    # The functions sets/unsets SHOW_SHADOW flag for all shapes currently included in the diagram.
    # @param [Boolean] show true if the shadow should be shown, otherwise false
    # @param [SHADOWMODE] style Shadow style
    # @see SHADOWMODE
    def show_shadows(show, style) end

    if Wx.has_feature?(:USE_DRAG_AND_DROP)

      # Start Drag&Drop operation with shapes included in the given list.
      # @param [Array<Wx::SF::Shape>] shapes List of shapes which should be dragged
      # @param [Wx::Point] start A point where the dragging operation has started
      # @return [Wx::DragResult] Drag result
      def do_drag_drop(shapes, start = Wx::Point.new(-1, -1)) end

    end

    # Copy selected shapes to the clipboard
    def copy

    end

    # Copy selected shapes to the clipboard and remove them from the canvas
    def cut

    end

    # Paste shapes stored in the clipboard to the canvas
    def paste

    end

    # Perform Undo operation (if available)
    def undo

    end

    # Perform Redo operation (if available)
    def redo

    end

    # Function returns true if some shapes can be copied to the clipboard (it means they are selected)
    # @return [Boolean]
    def can_copy

    end

    alias :can_copy? :can_copy

    # Function returns true if some shapes can be cut to the clipboard (it means they are selected)
    # @return [Boolean]
    def can_cut

    end

    alias :can_cut? :can_cut

    # Function returns true if some shapes can be copied from the clipboard to the canvas
    # (it means the clipboard contains stored shapes)
    # @return [Boolean]
    def can_paste

    end

    alias :can_paste? :can_paste

    # Function returns true if undo operation can be done
    # @return [Boolean]
    def can_undo

    end

    alias :can_undo? :can_undo

    # Function returns TRUE if Redo operation can be done
    # @return [Boolean]
    def can_redo

    end

    alias :can_redo? :can_redo

    # Function returns true if align_selected function can be invoked (if more than
    # @return [Boolean]
    def can_align_selected

    end

    alias :can_align_selected? :can_align_selected

    # Save current canvas state (for Undo/Redo operations)
    def save_canvas_state

    end

    # Clear all stored canvas states (no Undo/Redo operations will be available)
    def clear_canvas_history
    end

    # @!group Print methods

    # Print current canvas content.
    # @overload print(prompt = PROMPT)
    #   @param [Boolean] prompt If true (PROMPT) then the the native print dialog will be displayed before printing
    # @overload print(printout, prompt = PROMPT)
    #   @param [Wx::SF::Printout] printout user-defined printout object (inherited from Wx::SF::Printout class) for printing.
    #   @param [Boolean] prompt If true (PROMPT) then the the native print dialog will be displayed before printing
    # @see Wx::SF::Printout
    def print(*args) end

    # Show print preview.
    # @overload print_preview()
    # @overload print_preview(preview, printout = nil)
    #   @param [Wx::SF::Printout] preview user-defined printout object (inherited from Wx::SF::Printout class) used for print preview.
    #   @param [Wx::SF::Printout] printout user-defined printout class (inherited from Wx::SF::Printout class) used for printing.
    #   This parameter can be nil (in this case a print button will not be available in the print preview window).
    # @see Wx::SF::Printout
    def print_preview(*args) end

    # Show page setup dialog for printing.
    def page_setup

    end

    # @!endgroup

    # Convert device position to logical position.
    #
    # The function returns unscrolled unscaled canvas position.
    # @overload dp2lp(pos)
    #   @param [Wx::Point] pos Device position (for example mouse position)
    #   @return [Wx::Point] Logical position
    # @overload dp2lp(rct)
    #   @param [Wx::Rect] rct Device position (for example mouse position)
    #   @return [Wx::Rect] Logical position
    def dp2lp(arg) end

    # Convert logical position to device position.
    #
    # The function returns scrolled scaled canvas position.
    # @overload lp2dp(pos)
    #   @param [Wx::Point] pos Logical position (for example shape position)
    #   @return [Wx::Point] Device position
    # @overload lp2dp(rct)
    #   @param [Wx::Rect] rct Logical position (for example shape position)
    #   @return [Wx::Rect] Device position
    def lp2dp(arg) end

    # Search for any shape located at the (mouse cursor) position (result used by Wx::SF::ShapeCanvas#get_shape_under_cursor)
    # @param [Wx::Point] pos
    def update_shape_under_cursor_cache(pos) end

    # Get shape under current mouse cursor position (fast implementation - use everywhere
    # it is possible instead of much slower GetShapeAtPosition()).
    # @param [SEARCHMODE] mode Search mode
    # @return [Wx::SF::Shape,nil] shape if found, otherwise nil
    # @see SEARCHMODE, Wx::SF::ShapeCanvas#dp2lp, Wx::SF::ShapeCanvas#get_shape_at_position
    def get_shape_under_cursor(mode = SEARCHMODE::BOTH) end

    # Get shape at given logical position
    # @param [Wx::Point] pos Logical position
    # @param [Integer] zorder Z-order of searched shape (useful if several shapes are located
    # at the given position)
    # @param [SEARCHMODE] mode Search mode
    # @return [Wx::SF::Shape,nil] shape if found, otherwise nil
    # @see SEARCHMODE, Wx::SF::ShapeCanvas#dp2lp, Wx::SF::ShapeCanvas#get_shape_under_cursor
    def get_shape_at_position(pos, zorder = 1, mode = SEARCHMODE::BOTH) end

    # Get topmost handle at given position
    # @param [Wx::Point] pos Logical position
    # @return [Wx::SF::Shape::Handle,nil] shape handle if found, otherwise nil
    # @see Wx::SF::ShapeCanvas#dp2lp
    def get_topmost_handle_at_position(pos) end

    # Get list of all shapes located at given position
    # @param [Wx::Point] pos Logical position
    # @param [Array<Wx::SF::Shape>] shapes shape list where pointers to all found shapes will be stored
    # @return [Array<Wx::SF::Shape>] shapes shape list
    # @see Wx::SF::ShapeCanvas#dp2lp
    def get_shapes_at_position(pos, shapes = []) end

    # Get list of shapes located inside given rectangle
    # @param [Wx::Rect] rct Examined rectangle
    # @param [Array<Wx::SF::Shape>] shapes shape list where pointers to all found shapes will be stored
    # @return [Array<Wx::SF::Shape>] shapes shape list
    def get_shapes_inside(rct, shapes = []) end

    # Get list of selected shapes.
    # @param [Array<Wx::SF::Shape>] selection shape list where pointers to all selected shapes will be stored
    # @return [Array<Wx::SF::Shape>] shapes shape list
    def get_selected_shapes(selection = []) end

    # Get box bounding all shapes in the canvas.
    # @return [Wx::Rect] Total bounding box
    def get_total_bounding_box

    end

    # Get bounding box of all selected shapes.
    # @return [Wx::Rect] Selection bounding box
    def get_selection_bb

    end

    # Align selected shapes in given directions.
    #
    # Shapes will be aligned according to most far shape in appropriate direction.
    # @param [HALIGN] halign Horizontal alignment
    # @param [VALIGN] valign Vertical alignment
    def align_selected(halign, valign)
    end

    # @!group Style accessors

    # Set canvas style.
    #
    # Default value is STYLE::MULTI_SELECTION | STYLE::MULTI_SIZE_CHANGE | STYLE::DND | STYLE::UNDOREDO | STYLE::CLIPBOARD | STYLE::HOVERING | STYLE::HIGHLIGHTING
    # @param [STYLE] style Combination of the canvas styles
    # @see STYLE
    def set_style(style)
      @settings.style = style
    end
    alias :style= :set_style

    # Get current canvas style.
    def get_style
      @settings.style
    end
    alias :style :get_style

    # Add new style flag.
    # @param [STYLE] style canvas style to add
    def add_style(style)
      @settings.style |= style
    end

    # Remove given style flag.
    # @param [STYLE] style canvas style to remove
    def remove_style(style)
      @settings.style &= ~style
    end

    # Check whether given style flag is used.
    # @param [STYLE] style canvas style to check
    def contains_style(style)
      (@settings.style & style) != 0
    end
    alias :contains_style? :contains_style
    alias :has_style? :contains_style

    # @!endgroup

    # @!group Public attribute accessors

    # Set canvas background color.
    # @param [Wx::Colour] col Background color
    def set_canvas_colour(col)
      @settings.background_color = col
    end
    alias :canvas_colour= :set_canvas_colour

    # Get canvas background color.
    # @return [Wx::Colour] Background color
    def get_canvas_colour
      @settings.background_color
    end
    alias :canvas_colour :get_canvas_colour

    # Set starting gradient color.
    # @param [Wx::Colour] col Color
    def set_gradient_from(col)
      @settings.gradient_from = col
    end
    alias :gradient_from= :set_gradient_from

    # Get starting gradient color.
    # @return [Wx::Colour] Color
    def get_gradient_from
      @settings.gradient_from
    end
    alias :gradient_from :get_gradient_from

    # Set ending gradient color.
    # @param [Wx::Colour] col Color
    def set_gradient_to(col)
      @settings.gradient_to = col
    end
    alias :gradient_to= :set_gradient_to

    # Get ending gradient color.
    # @return [Wx::Colour] Color
    def get_gradient_to
      @settings.gradient_to
    end
    alias :gradient_to :get_gradient_to

    # Get grid size.
    # @return [Wx::Size] Grid size
    def get_grid_size
      @settings.grid_size
    end
    alias :grid_size :get_grid_size

    # Set grid size.
    # @param [Wx::Size] grid Grid size
    def set_grid_size(grid)
      @settings.grid_size = grid
    end
    alias :grid_size= :set_grid_size

    # Set grid line multiple.
    #
    # Grid lines will be drawn in a distance calculated as grid size multiplicated by this value.
    # Default value is 1.
    # @param [Integer] multiple Multiple value
    def set_grid_line_mult(multiple)
      @settings.grid_line_mult = multiple
    end
    alias :grid_line_mult= :set_grid_line_mult

    # Get grid line multiple.
    # @return [Integer] Value by which a grid size will be multiplicated to determine grid lines distance
    def get_grid_line_mult
      @settings.grid_line_mult
    end
    alias :grid_line_mult :get_grid_line_mult

    # Set grid color.
    # @param [Wx::Colour] col Grid color
    def set_grid_colour(col)
      @settings.grid_color = col
    end
    alias :grid_colour= :set_grid_colour

    # Get grid color.
    # @return [Wx::Colour] Grid color
    def get_grid_colour
      @settings.grid_color
    end
    alias :grid_colour :get_grid_colour

    # Set grid line style.
    # @param [Wx::PenStyle] style Line style
    def set_grid_style(style)
      @settings.grid_style = style
    end
    alias :grid_style= :set_grid_style

    # Get grid line style.
    # @return [Wx::PenStyle] Line style
    def get_grid_style
      @settings.grid_style
    end
    alias :grid_style :get_grid_style

    # Set shadow offset.
    # @param [Wx::RealPoint] offset Shadow offset
    def set_shadow_offset(offset)
      @settings.shadow_offset = offset
    end
    alias :shadow_offset= :set_shadow_offset

    # Get shadow offset.
    # @return [Wx::RealPoint] Shadow offset
    def get_shadow_offset
      @settings.shadow_offset
    end
    alias :shadow_offset :get_shadow_offset

    # Set shadow fill (used for shadows of non-text shapes only).
    # @param [Wx::Brush] brush Reference to brush object
    def set_shadow_fill(brush)
      @settings.shadow_fill = brush
    end
    alias :shadow_fill= :set_shadow_fill

    # Get shadow fill.
    # @return [Wx::Brush] Current shadow brush
    def get_shadow_fill
      @settings.shadow_fill
    end
    alias :shadow_fill :get_shadow_fill

    # Set horizontal align of printed drawing.
    # @param [HALIGN] val Horizontal align
    # @see HALIGN
    def set_print_h_align(val)
      @settings.print_h_align = val
    end
    alias :print_h_align= :set_print_h_align

    # Get horizontal align of printed drawing.
    # @return [HALIGN] Current horizontal align
    # @see HALIGN
    def get_print_h_align
      @settings.print_h_align
    end
    alias :print_h_align :get_print_h_align

    # Set vertical align of printed drawing.
    # @param [VALIGN] val Vertical align
    # @see VALIGN
    def set_print_v_align(val)
      @settings.print_v_align = val
    end
    alias :print_v_align= :set_print_v_align

    # Get vertical align of printed drawing.
    # @return [VALIGN] Current vertical align
    # @see VALIGN
    def get_print_v_align
      @settings.print_v_align
    end
    alias :print_v_align :get_print_v_align

    # Set printing mode for this canvas.
    # @param [PRINTMODE] mode Printing mode
    # @see PRINTMODE
    def set_print_mode(mode)
      @settings.print_mode = mode
    end
    alias :print_mode= :set_print_mode

    # Get printing mode for this canvas.
    # @return [PRINTMODE] Current printing mode
    # #see PRINTMODE
    def get_print_mode
      @settings.print_mode
    end
    alias :print_mode :get_print_mode

    # Set canvas scale.
    # @param [Float] scale Scale value
    def set_scale(scale)
      @settings.scale = scale
    end
    alias :scale= :set_scale

    # Set minimal allowed scale (for mouse wheel scale change).
    # @param [Float] scale Minimal scale
    def set_min_scale(scale)
      @settings.min_scale = scale
    end
    alias :min_scale= :set_min_scale

    # Get minimal allowed scale (for mouse wheel scale change).
    # @return [Float] Minimal scale
    def get_min_scale
      @settings.min_scale
    end
    alias :min_scale :get_min_scale

    # Set maximal allowed scale (for mouse wheel scale change).
    # @param [Float] scale Maximal scale
    def set_max_scale(scale)
      @settings.max_scale = scale
    end
    alias :max_scale= :set_max_scale

    # Set maximal allowed scale (for mouse wheel scale change).
    # @return [FLOAT] Maximal scale
    def get_max_scale
      @settings.max_scale
    end
    alias :max_scale :get_max_scale

    # Get the canvas scale.
    # @return [Float] Canvas scale
    def get_scale
      @settings.scale
    end
    alias :scale :get_scale

    # @!endgroup

    # Set the canvas scale so a whole diagram is visible.
    def set_scale_to_view_all

    end

    # Scroll the shape canvas so the given shape will be located in its center.
    # @param [Wx::SF::Shape] shape Pointer to focused shape
    def scroll_to_shape(shape)

    end

    # Get canvas working mode.
    # @return [MODE] Working mode
    # @see MODE
    def get_mode
      @working_mode
    end
    alias :mode :get_mode

    # Set default hover color.
    # @param [Wx::Colour] col Hover color.
    def set_hover_colour(col)

    end
    alias :hover_colour= :set_hover_colour

    # Get default hover colour.
    # @return [Wx::Colour] Hover colour
    def get_hover_colour
      @settings.common_hover_color
    end
    alias :hover_colour :get_hover_colour

    # Get canvas history manager.
    # @return [Wx::SF::CanvasHistory] the canvas history manager
    # @see Wx::SF::CanvasHistory
    def get_history_manager
      @canvas_history
    end
    alias :history_manager :get_history_manager

    # Update given position so it will fit canvas grid (if enabled).
    # @param [Wx::Point] pos Position which should be updated
    # @return [Wx::Point] Updated position
    def fit_position_to_grid(pos)

    end

	  # Update size of multi selection rectangle
    def update_multiedit_size

    end

	  # Update scroll window virtual size so it can display all shape canvas
    def update_virtual_size

    end

	  # Move all shapes so none of it will be located in negative position
    def move_shapes_from_negatives

    end

	  # Center diagram in accordance to the shape canvas extent.
    def center_shapes
      
    end
    
    # Validate selection (remove redundantly selected shapes etc...).
    # @param [Array<Wx::SF::Shape>] selection List of selected shapes that should be validated
    def validate_selection(selection)

    end

	  # Function responsible for drawing of the canvas's content to given DC. The default
    # implementation draws actual objects managed by assigned diagram manager.
    # @param [Wx::DC] dc device context where the shapes will be drawn to
    # @param [Boolean] from_paint Set the argument to true if the dc argument refers to the Wx::PaintDC instance
    # or derived classes (i.e. the function is called as a response to Wx::EVT_PAINT event)
    def draw_content(dc, from_paint)

    end

	  # Function responsible for drawing of the canvas's background to given DC. The default
    # implementation draws canvas background and grid.
    # @param [Wx::DC] dc device context where the shapes will be drawn to
    # @param [Boolean] from_paint Set the argument to true if the dc argument refers to the Wx::PaintDC instance
    # or derived classes (i.e. the function is called as a response to Wx::EVT_PAINT event)
    def draw_background(dc, from_paint)

    end

	  # Function responsible for drawing of the canvas's foreground to given DC. The default
    # do nothing.
    # @param [Wx::DC] dc device context where the shapes will be drawn to
    # @param [Boolean] from_paint Set the argument to true if the dc argument refers to the Wx::PaintDC instance
    # or derived classes (i.e. the function is called as a response to Wx::EVT_PAINT event)
    def draw_foreground(dc, from_paint)

    end

    # Get reference to multiselection box
    # @return [Wx::SF::MultiSelRect] multiselection box object
    def get_multiselection_box
      @shp_multi_edit
    end

    # Close and delete all opened text editing controls actually used by editable text shapes 
    def delete_all_text_ctrls
      
    end

    # @!group Public event handlers

    # Event handler called when the canvas is clicked by
    # the left mouse button. The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param [Wx::MouseEvent] event Mouse event
    # @see _on_left_down
    def on_left_down(event)

    end

    # Event handler called when the canvas is double-clicked by
    # the left mouse button. The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param [Wx::MouseEvent] event Mouse event
    # @see _on_left_double_click
    def on_left_double_click(event)

    end

    # Event handler called when the left mouse button is released.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param [Wx::MouseEvent] event Mouse event
    # @see _on_left_up
    def on_left_up(event)

    end

    # Event handler called when the canvas is clicked by
    # the right mouse button. The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param [Wx::MouseEvent] event Mouse event
    # @see _on_right_down
    def on_right_down(event)

    end

    # Event handler called when the canvas is double-clicked by
    # the right mouse button. The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param [Wx::MouseEvent] event Mouse event
    # @see _on_right_double_click
    def on_right_double_click(event)

    end

    # Event handler called when the right mouse button is released.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param [Wx::MouseEvent] event Mouse event
    # @see _on_right_up
    def on_right_up(event)

    end

    # Event handler called when the mouse pointer is moved.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param [Wx::MouseEvent] event Mouse event
    # @see _on_mouse_move
    def on_mouse_move(event)

    end

    # Event handler called when the mouse wheel position is changed.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param event Mouse event
    # @param [Wx::MouseEvent] event Mouse event
    def on_mouse_wheel(event)

    end

    # Event handler called when any key is pressed.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param [Wx::KeyEvent] event Keyboard event
    # @see _on_key_down
    def on_key_down(event)

    end

    # Event handler called when any editable text shape is changed.
    # The function can be overridden if necessary.
    # The function is called by the framework and its default implementation
    # generates Wx::SF::EVT_SF_TEXT_CHANGE event.
    # @param [Wx::SF::EditTextShape] shape Changed Wx::SF::EditTextShape object
    # @see Wx::SF::EditTextShape#edit_label
    # @see Wx::SF::ShapeTextEvent
    def on_text_change(shape)

    end

    # Event handler called after successful connection creation. The function
    # can be overridden if necessary. The default implementation
    # generates Wx::SF::EVT_SF_LINE_DONE event.
    # @param [Wx::SF::LineShape] connection new connection object
    # @see start_interactive_connection
    # @see Wx::SF::ShapeEvent
    def on_connection_finished(connection)

    end

    # Event handler called after successful connection creation in
    # order to allow developer to perform some kind of checks
    # before the connection is really added to the diagram. The function
    # can be overridden if necessary. The default implementation
    # generates Wx::SF::EVT_SF_LINE_DONE event.
    # @param [Wx::SF::LineShape] connection new connection object
    # @return [PRECONNECTIONFINISHEDSTATE] PRECONNECTIONFINISHEDSTATE::OK if the connection is accepted, otherwise
    # if the generated event has been vetoed the connection creation is cancelled
    # @see start_interactive_connection
    # @see Wx::SF::ShapeEvent
    def on_pre_connection_finished(connection)

    end

    if Wx.has_feature?(:USE_DRAG_AND_DROP)

    # Event handler called by the framework after any dragged shapes
    # are dropped to the canvas. The default implementation
    # generates Wx::SF::EVT_SF_ON_DROP event.
    # @param [Integer] x X-coordinate of a position the data was dropped to
    # @param [Integer] y Y-coordinate of a position the data was dropped to
    # @param [Wx::DragResult] deflt Drag result
    # @param [Array<Wx::SF::Shape>] dropped a list containing the dropped data
    # @see Wx::SF::CanvasDropTarget
    # @see Wx::SF::ShapeDropEvent
    def on_drop(x, y, deflt, dropped)

    end

    end

    # Event handler called by the framework after pasting of shapes
    # from the clipboard to the canvas. The default implementation
    # generates Wx::SF::EVT_SF_ON_PASTE event.
    # @param [Array<Wx::SF::Shape>] pasted a list containing the pasted data
    # @see Wx::SF::ShapeCanvas#paste
    # @see Wx::SF::ShapePasteEvent
    def on_paste(pasted)

    end

    # Event handler called if canvas virtual size is going to be updated.
    # The default implementation does nothing but the function can be overridden by
    # a user to modify calculated virtual canvas size.
    # @param [Wx::Rect] virtrct Calculated canvas virtual size
    def on_update_virtual_size(virtrct)

    end

    # @!endgroup

    private

    #  Validate selection so the shapes in the given list can be processed by the clipboard functions
    # @param [Array<Wx::SF::Shape>] selection
    # @param [Boolean] storeprevpos
    def validate_selection_for_clipboard(selection, bool storeprevpos)

    end

    #  Append connections assigned to shapes in given list to this list as well
    # @param [Wx::SF::Shape] shape
    # @param [Array<Wx::SF::Shape>] selection
    # @param [Boolean] childrenonly
    def append_assigned_connections(shape, selection, childrenonly)

    end

    #  Initialize printing framework 
    def initialize_printing

    end

    #  Deinitialize printing framework
    def deinitialize_printing

    end

    #  Remove given shape for temporary containers
    # @param [Wx::SF::Shape] shape
    def remove_from_temporaries(shape)

    end

    #  Clear all temporary containers 
    def clear_temporaries

    end

    #  Assign give shape to parent at given location (if exists)
    # @param [Wx::SF::Shape] shape
    # @param [Wx::Point] parentpos
    def reparent_shape(shape, parentpos)

    end

    #  Store previous shape's position modified in validate_selection_for_clipboard() function
    # @param [Wx::SF::Shape] shape
    def store_prev_position(shape)

    end

    #  Restore previously stored shapes' positions and clear the storage 
    def restore_prev_positions

    end

    # private event handlers

	  # Event handler called when the canvas should be repainted.
	  # @param [Wx::PaintEvent] event Paint event
    def _on_paint(event)

    end

	  # Event handler called when the canvas should be erased.
	  # @param [Wx::EraseEvent] event Erase event
    def _on_erase_background(event)

    end

	  # Event handler called when the mouse pointer leaves the canvas window.
	  # @param [Wx::MouseEvent] event Mouse event
    def _on_leave_window(event)

    end

	  # Event handler called when the mouse pointer enters the canvas window.
	  # @param [Wx::MouseEvent] event Mouse event
    def _on_enter_window(event)

    end

	  # Event handler called when the canvas size has changed.
	  # @param [Wx::SizeEvent] event Size event
    def _on_resize(event)

    end
    
    # original private event handlers
    
	  # Original private event handler called when the canvas is clicked by
	  # left mouse button. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
	  # @param [Wx::MouseEvent] event Mouse event
	  # @see Wx::SF::ShapeCanvas#on_left_down
    def _on_left_down(event)

    end

	  # Original private event handler called when the canvas is double-clicked by
	  # left mouse button. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
	  # @see Wx::SF::ShapeCanvas#on_left_double_click
    def _on_left_double_click(event)

    end

	  # Original private event handler called when the left mouse button
	  # is release above the canvas. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_left_up
    def _on_left_up(event)

    end

	  # Original private event handler called when the canvas is clicked by
	  # right mouse button. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_right_down
    def _on_right_down(event)

    end

	  # Original private event handler called when the canvas is double-clicked by
	  # right mouse button. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_right_double_click
    def _on_right_double_click(event)

    end

	  # Original private event handler called when the right mouse button
	  # is release above the canvas. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_right_up
    def _on_right_up(event)

    end

	  # Original private event handler called when the mouse pointer is moving above
	  # the canvas. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_mouse_move
    def _on_mouse_move(event)

    end

	  # Original private event handler called when the mouse wheel pocition is changed.
	  # The handler calls user-overridable event handler function and skips the event
	  # for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_mouse_wheel
    def _on_mouse_wheel(event)

    end

	  # Original private event handler called when any key is pressed.
	  # The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
	  # @param [Wx::KeyEvent] event Keyboard event
	  # @see Wx::SF::ShapeCanvas#on_key_down
    def _on_key_down(event)

    end

    if Wx.has_feature?(:USE_DRAG_AND_DROP)

	  # Function is called by associated wxSFCanvasDropTarget after any dragged shapes
	  # are dropped to the canvas.
	  # @param [Integer] x X-coordinate of a position the data was dropped to
	  # @param [Integer] y Y-coordinate of a position the data was dropped to
	  # @param [Wx::DragResult] deflt Drag result
	  # @param [Wx::DataObject] data a data object encapsulating dropped data
	  # @see Wx::SF::CanvasDropTarget
    def _on_drop(x, y, deflt, data)

    end
      
    end
    
  end # class ShapeCanvas

end

# module Wx::SF
