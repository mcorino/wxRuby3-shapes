# Wx::SF::ShapeCanvas - shape canvas class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shape_data_object'
require 'wx/shapes/canvas_history'
require 'wx/shapes/printout'

require 'tempfile'
require 'fileutils'

module Wx::SF

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
        deflt
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

    # Change mode flags
    class CHANGE < Wx::Enum
      SET_SCALE = self.new(0)
      RESCALED = self.new(1)
      VIRTUAL_SIZE = self.new(2)
      FOCUS = self.new(3)
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

    class PRECON_FINISH_STATE < Wx::Enum
      # Finish line connection.
      OK = self.new(0)
      # Cancel line connection and abort the interactive connection.
      FAILED_AND_CANCEL_LINE = self.new(1)
      # Cancel line connection and continue with the interactive connection.
      FAILED_AND_CONTINUE_EDIT = self.new(2)
    end

    # Default values
    module DEFAULT
      class << self
        # Default value of Wx::SF::CanvasSettings @background_color data member
        def background_color; @bgcolor ||= Wx::Colour.new(240, 240, 240); end
        # Default value of Wx::SF::CanvasSettings @common_hover_color data member
        def hover_color; @hvrcolor ||= Wx::Colour.new(120, 120, 255); end
        # Default value of Wx::SF::CanvasSettings @grid_color data member
        def grid_color; @gridcolor ||= Wx::Colour.new(200, 200, 200); end
        # Default value of Wx::SF::CanvasSettings @gradient_from data member
        def gradient_from; @gradcolor_from ||= Wx::Colour.new(240, 240, 240); end
        # Default value of Wx::SF::CanvasSettings @gradient_to data member
        def gradient_to; @gradcolor_to ||= Wx::Colour.new(200, 200, 255); end
        # Default shadow colour
        def shadow_color; @shadowcolor ||= Wx::Colour.new(150, 150, 150, 128); end
        # Default value of Wx::SF::CanvasSettings @shadow_fill data member
        def shadow_brush; @shadowbrush ||= Wx::Brush.new(shadow_color, Wx::BrushStyle::BRUSHSTYLE_SOLID); end
      end
      # Default value of Wx::SF::CanvasSettings @grid_size data member
      GRIDSIZE = Wx::Size.new(10, 10)
      # Default value of Wx::SF::CanvasSettings @grid_line_mult data member
      GRIDLINEMULT = 1
      # Default value of Wx::SF::CanvasSettings @grid_style data member
      GRIDSTYLE = Wx::PenStyle::PENSTYLE_SOLID
      # Default value of Wx::SF::CanvasSettings @style data member
      CANVAS_STYLE = STYLE::DEFAULT_CANVAS_STYLE
      # Default value of Wx::SF::CanvasSettings @shadow_offset data member
      SHADOWOFFSET = Wx::RealPoint.new(4, 4)
      # Default value of Wx::SF::CanvasSettings @print_h_align data member
      PRINT_HALIGN = HALIGN::CENTER
      # Default value of Wx::SF::CanvasSettings @print_v_align data member
      PRINT_VALIGN = VALIGN::MIDDLE
      # Default value of Wx::SF::CanvasSettings @print_mode data member
      PRINT_MODE = PRINTMODE::FIT_TO_MARGINS
      # Default value of Wx::SF::CanvasSettings @min_scale data member
      SCALE_MIN = 0.1
      # Default value of Wx::SF::CanvasSettings @max_scale data member
      SCALE_MAX = 5.0
    end

    class << self

      def gc_enabled?
        if @gc_enabled.nil?
          @gc_enabled = Wx.has_feature?(:USE_GRAPHICS_CONTEXT)
        end
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

      TLS_LOADING_VERSION_KEY = :loading_version.freeze
      private_constant :TLS_LOADING_VERSION_KEY

      def compat_loading?
        !!::Thread::current[TLS_LOADING_VERSION_KEY]
      end

      def compat_loading_version
        ::Thread::current[TLS_LOADING_VERSION_KEY]
      end

      def set_compat_loading(ver_info)
        ::Thread::current[TLS_LOADING_VERSION_KEY] = ver_info
      end

      def reset_compat_loading
        ::Thread::current[TLS_LOADING_VERSION_KEY] = nil
      end

      def print_data
        _init_printing unless @print_data
        @print_data
      end

      def print_data=(pd)
        @print_data = pd
      end

      def page_setup_data
        _init_printing unless @page_setup_data
        @page_setup_data
      end

      def page_setup_data=(psd)
        @page_setup_data = psd
      end

      def _init_printing
        @print_data = Wx::PRT::PrintData.new
        # You could set an initial paper size here
        #	@print_data.set_paper_id(Wx::PaperSize::PAPER_LETTER) # for Americans
        @print_data.set_paper_id(Wx::PaperSize::PAPER_A4)	# for everyone else

        # copy over initial paper size from print record
        @page_setup_data = Wx::PRT::PageSetupDialogData.new(@print_data)
        # Set some initial page margins in mm.
        @page_setup_data.set_margin_top_left([15, 15])
        @page_setup_data.set_margin_bottom_right([15, 15])
      end
      private :_init_printing

    end

    # Auxiliary serializable class encapsulating canvas version info
    # and providing version check on loading.
    class Version

      class Exception < SFException; end

      VersionInfo = ::Struct.new(:major, :minor, :release) do
        def to_s
          "#{major}.#{minor}.#{release}"
        end
      end

      include FIRM::Serializable

      property :version_info

      def initialize
        # get version numbers as [major, minor, release]
        @version_info = VersionInfo.new(*Wx::SF::VERSION.split(/\D/).shift(3).collect { |s| s.to_i })
      end

      attr_reader :version_info

      # Deserialization only.
      def set_version_info(ver_info)
        if @version_info.major < ver_info.major ||
            (@version_info.major == ver_info.major && @version_info.minor < ver_info.minor)
          ::Kernel.raise Version::Exception, "Incompatible Wx::SF diagram version #{ver_info} cannot be loaded (current Wx::SF version #{@version_info})."
        elsif @version_info.major > ver_info.major ||
            (@version_info.major == ver_info.major && @version_info.minor > ver_info.minor)
          # this should normally work but may give trouble
          # set compat loading info
          ShapeCanvas.set_compat_loading(ver_info)
        else
          # this should never give any trouble
        end
      end
      private :set_version_info

    end

    # Auxiliary serializable class encapsulating the canvas properties.
    class Settings

      include FIRM::Serializable

      include DEFAULT

      property :scale, :min_scale, :max_scale, :background_color, :common_hover_color,
               :grid_size, :grid_line_mult, :grid_color, :grid_style,
               :gradient_from, :gradient_to, :style, :shadow_offset, :shadow_fill,
               :print_h_align, :print_v_align, :print_mode

      def initialize
        @scale = 1.0
        @min_scale = SCALE_MIN
        @max_scale = SCALE_MAX
        @background_color = DEFAULT.background_color
        @common_hover_color = DEFAULT.hover_color
        @grid_size = GRIDSIZE.dup
        @grid_line_mult = GRIDLINEMULT
        @grid_color = DEFAULT.grid_color
        @grid_style = GRIDSTYLE
        @gradient_from = DEFAULT.gradient_from
        @gradient_to = DEFAULT.gradient_to
        @style = CANVAS_STYLE
        @shadow_offset = SHADOWOFFSET.dup
        @shadow_fill = DEFAULT.shadow_brush
        @print_h_align = PRINT_HALIGN
        @print_v_align = PRINT_VALIGN
        @print_mode = PRINT_MODE
      end

      attr_accessor :scale, :min_scale, :max_scale, :background_color, :common_hover_color,
                    :grid_size, :grid_line_mult, :grid_color, :grid_style,
                    :gradient_from, :gradient_to, :style, :shadow_offset, :shadow_fill,
                    :print_h_align, :print_v_align, :print_mode

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
      super()

      @dnd_started_here = false
      @dnd_started_at = nil
      @can_save_state_on_mouse_up = false
      @working_mode = MODE::READY
      @selection_mode = SELECTIONMODE::NORMAL
      @selected_handle = nil
      @selection_start = Wx::RealPoint.new
      @new_line_shape = nil
      @unselected_shape_under_cursor = nil
      @selected_shape_under_cursor = nil
      @topmost_shape_under_cursor = nil
      @current_shapes = []
      @invalidate_rect = nil

      @prev_mouse_pos = Wx::Point.new
      @prev_positions = {}

      @settings = Settings.new
      @canvas_history = CanvasHistory.new

      if diagram
        parent = mixed_args.first.is_a?(Wx::Window) ? mixed_args.shift : nil
        real_args = []
        begin
          real_args = [parent] + Wx::ScrolledWindow.args_as_list(*mixed_args)
          create(*real_args)
        rescue => err
          msg = "Error initializing #{self.inspect}\n" +
            " : #{err.message} \n" +
            "Provided are #{real_args} \n" +
            "Correct parameters for #{self.class.name}.new are:\n" +
            self.class.describe_constructor

          new_err = err.class.new(msg)
          new_err.set_backtrace(caller)
          Kernel.raise new_err
        end

        self.diagram = diagram

        save_canvas_state
      end
      
      # set up event handlers
      evt_paint :_on_paint
      evt_erase_background :_on_erase_background
      evt_left_down :_on_left_down
      evt_left_up :_on_left_up
      evt_right_down :_on_right_down
      evt_right_up :_on_right_up
      evt_left_dclick :_on_left_double_click
      evt_right_dclick :_on_right_double_click
      evt_motion :_on_mouse_move
      evt_mousewheel :_on_mouse_wheel
      evt_key_down :_on_key_down
      evt_enter_window :_on_enter_window
      evt_leave_window :_on_leave_window
      evt_size :_on_resize
    end

    # Creates the window in two-step construction mode. set_diagram() function must also be called to complete the canvas initialization.
    # @param [Wx::Window] parent Parent window
    # @param [Integer] id Window ID
    # @param [Wx::Point] pos Initial position
    # @param [Wx::Size] size Initial size
    # @param [Integer] style Window style
    # @param [String] name Window name
    def create(parent, id = -1, pos = Wx::DEFAULT_POSITION, size = Wx::DEFAULT_SIZE, style = (Wx::HSCROLL | Wx::VSCROLL), name = "Wx::ScrolledWindow")
      # NOTE: user must call Wx::SF::ShapeCanvas#set_diagram() to complete
      # canvas initialization!

      # perform basic window initialization
      super

      # set drop target
      if Wx.has_feature?(:USE_DRAG_AND_DROP)
        set_drop_target(Wx::SF::CanvasDropTarget.new(Wx::SF::ShapeDataObject.new, self))
      end

      # initialize selection rectangle
      @shp_selection = MultiSelRect.new
      @shp_selection.create_handles
      @shp_selection.select(true)
      @shp_selection.show(false)
      @shp_selection.show_handles(true)

      # initialize multi-edit rectangle
      @shp_multi_edit = MultiSelRect.new
      @shp_multi_edit.create_handles
      @shp_multi_edit.select(true)
      @shp_multi_edit.show(false)
      @shp_multi_edit.show_handles(true)

      set_scrollbars(5, 5, 100, 100)
      set_background_style(Wx::BG_STYLE_PAINT)

      true
    end

    attr_reader :settings

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
      clear_temporaries
      @diagram.update_all
    end

    # Load serialized canvas content (diagrams).
    # @overload load_canvas(file)
    #   @param [String] file Full file name
    #   @param [Symbol,nil] format specifies the serialization format to use;
    #          determined from file extension if not specified defaulting to :json for unknown extensions
    #   @return [self]
    # @overload load_canvas(io)
    #   @param [IO] io IO object
    #   @param [Symbol,nil] format specifies the serialization format to use (by default :json)
    #   @return [self]
    def load_canvas(io, format: nil)
      # get IO stream to read from
      ios = if io.is_a?(::String)
              format ||= case File.extname(io)
                         when '.json' then :json
                         when '.yaml', '.yml' then :yaml
                         when '.xml' then :xml
                         else
                           :json
                         end
              File.open(io, 'r')
            else
              format ||= :json
              io
            end
      old_diagram = @diagram
      old_settings = @settings
      begin
        begin
          _, @settings, diagram = FIRM.deserialize(ios, format: format)
        rescue SFException
          ::Kernel.raise
        rescue ::Exception
          ::Kernel.raise SFException, "Failed to load canvas: #{$!.message}"
        ensure
          ShapeCanvas.reset_compat_loading
          ios.close if io.is_a?(::String) && ios
        end
        set_diagram(diagram)
        clear_canvas_history
        save_canvas_state
        set_scale(@settings.scale)
        update_virtual_size
        refresh(false)
      rescue Exception
        # restore previous state
        @settings = old_settings
        set_diagram(old_diagram)
        clear_canvas_history
        save_canvas_state
        set_scale(@settings.scale)
        update_virtual_size
        refresh(false)
        # propagate exception
        ::Kernel.raise
      end

      @diagram.set_modified(false)

      self
    end

    # Save  canvas content (diagrams).
    # @overload save_canvas(file, compact: true)
    #   @param [String] file Full file name
    #   @param [Boolean] compact specifies whether to write content in compact mode (true) or not (false)
    #   @param [Symbol,nil] format specifies the serialization format to use;
    #          determined from file extension if not specified defaulting to :json for unknown extensions
    #   @return [self]
    # @overload save_canvas(io, compact: true)
    #   @param [IO] io IO object
    #   @param [Boolean] compact specifies whether to write content in compact mode (true) or not (false)
    #   @param [Symbol,nil] format specifies the serialization format to use (by default :json)
    #   @return [self]
    def save_canvas(io, compact: true, format: nil)
      return self unless @diagram
      # get IO stream to write to
      ios = if io.is_a?(::String)
              format ||= case File.extname(io)
                         when '.json' then :json
                         when '.yaml', '.yml' then :yaml
                         when '.xml' then :xml
                         else
                           :json
                         end
              Tempfile.new(File.basename(io, '.*'))
            else
              format ||= :json
              io
            end
      # write canvas data to temp file
      begin
        [Version.new, @settings, @diagram].serialize(ios, pretty: !compact, format: format)
      rescue SFException
        ::Kernel.raise
      rescue Exception
        ::Kernel.raise SFException, "Error writing canvas: #{$!.message}"
      end
      if io.is_a?(::String)
        ios.close(false) # close but keep temp file
        full_path = File.absolute_path(io)
        if File.exist?(full_path)
          # create temporary backup
          ftmp = Tempfile.new(File.basename(io))
          ftmp_name = ftmp.path.dup
          ftmp.close(true) # close AND unlink
          FileUtils::mv(full_path, ftmp_name) # backup existing file
          # replace original
          begin
            # rename newly generated file
            FileUtils.mv(ios.path, full_path)
            # preserve file mode
            FileUtils.chmod(File.lstat(ftmp_name).mode, full_path)
          rescue Exception
            # restore backup
            FileUtils.mv(ftmp_name, full_path)
            ::Kernel.raise SFException, "Unable to save canvas file #{io}: #{$!.message}"
          end
          # remove backup
          FileUtils.rm_f(ftmp_name)
        else
          begin
            # rename newly generated file
            FileUtils.mv(ios.path, full_path)
          rescue Exception
            ::Kernel.raise SFException, "Unable to save canvas file #{io}: #{$!.message}"
          end
        end
      end

      @diagram.set_modified(false)

      self
    end

    # @overload save_canvas_to_image(type: Wx::BITMAP_TYPE_BMP, background: true, scale: -1.0)
    #   Export canvas content to image.
    #   @param [Wx::BitmapType] type Image type. See Wx::BitmapType for more details. Default type is Wx::BITMAP_TYPE_BMP.
    #   @param [Boolean] background Export also diagram background
    #   @param [Float] scale Image scale. If -1 then current canvas scale id used.
    #   @return [Wx::Bitmap,nil] exported canvas image or nil if failed to create bitmap
    # @overload save_canvas_to_image(file, type: Wx::BITMAP_TYPE_BMP, background: true, scale: -1.0)
    #   Export canvas content to image file.
    #   @param [String] file Full file name
    #   @param [Wx::BitmapType] type Image type. See Wx::BitmapType for more details. Default type is Wx::BITMAP_TYPE_BMP.
    #   @param [Boolean] background Export also diagram background
    #   @param [Float] scale Image scale. If -1 then current canvas scale id used.
    #   @return [Boolean] true if saving the image to file succeeded, false otherwise
    def save_canvas_to_image(file = nil, type: Wx::BITMAP_TYPE_BMP, background: true, scale: -1.0)
      # create memory DC a draw the canvas content into

      prev_scale = get_scale
      scale = prev_scale if scale == -1

      bmp_bb = get_total_bounding_box

      bmp_bb.left = (bmp_bb.left * scale).to_i
      bmp_bb.top = (bmp_bb.top * scale).to_i
      bmp_bb.width = (bmp_bb.width * scale).to_i
      bmp_bb.height = (bmp_bb.height * scale).to_i

      bmp_bb.inflate!(@settings.grid_size * scale)

      outbmp = Wx::Bitmap.new(bmp_bb.width, bmp_bb.height)
      Wx::MemoryDC.draw_on(outbmp) do |mdc|

        Wx::ScaledDC.draw_on(mdc, scale) do |outdc|

          if outdc.ok?
            set_scale(scale) if scale != prev_scale

            outdc.set_device_origin(-bmp_bb.left, -bmp_bb.top)

            prev_style = get_style
            prev_colour = get_canvas_colour

            unless background
              remove_style(STYLE::GRADIENT_BACKGROUND)
              remove_style(STYLE::GRID_SHOW)
              set_canvas_colour(Wx::WHITE)
            end

            draw_background(outdc, NOT_FROM_PAINT)
            draw_content(outdc, NOT_FROM_PAINT)
            draw_foreground( outdc, NOT_FROM_PAINT)

            unless background
              set_style(prev_style)
              set_canvas_colour(prev_colour)
            end

            set_scale(prev_scale) if scale != prev_scale

            if file
              return outbmp.save_file(file, type)
            else
              return outbmp
            end
          elsif file
            Wx.message_box('Could not create output bitmap.', 'wxRuby ShapeFramework', Wx::OK | Wx::ICON_ERROR)
          end
        end
      end
      nil
    end

    def _start_interactive_connection(lpos, src_shape, cpt)
      if @new_line_shape
        @working_mode = MODE::CREATECONNECTION
        @new_line_shape.send(:set_line_mode, LineShape::LINEMODE::UNDERCONSTRUCTION)

        @new_line_shape.set_src_shape(src_shape)

        # switch on the "under-construction" mode
        @new_line_shape.send(:set_unfinished_point, lpos)
        # assign starting point of new line shapes to the nearest connection point of
        # connected shape if exists
        @new_line_shape.set_starting_connection_point(cpt)
        ERRCODE::OK
      else
        ERRCODE::NOT_CREATED
      end
    end
    private :_start_interactive_connection

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
    def start_interactive_connection(*args)
      return ERRCODE::INVALID_INPUT unless @diagram

      shape_info = shape = pos = connection_point = nil
      shape_klass = nil
      case args.first
      when Wx::SF::LineShape
        shape = args.shift
        shape_klass = shape.class
        if args.first.is_a?(Wx::SF::ConnectionPoint)
          connection_point = args.shift
        end
        pos = args.shift.to_point
      when ::Class
        shape_info = args.shift
        pos = args.shift.to_point
        shape_klass = shape_info
      end
      ::Kernel.raise ArgumentError, "Invalid arguments #{args}" unless args.empty?
      return ERRCODE::INVALID_INPUT unless pos

      lpos = dp2lp(pos)

      if @working_mode == MODE::READY && ((shape_info && shape_info <= Wx::SF::LineShape) || (shape.is_a?(Wx::SF::LineShape)))

        if connection_point

          if @diagram.contains?(shape)
            @new_line_shape = shape
          else
            @new_line_shape = @diagram.add_shape(shape, nil, Wx::DEFAULT_POSITION, INITIALIZE, DONT_SAVE_STATE)
          end
          return _start_interactive_connection(lpos, connection_point.get_parent_shape, connection_point)

        else

          shape_under = get_shape_at_position(lpos)
          if shape_info
            # propagate request for interactive connection if requested
            shape_under = shape_under.get_parent_shape while shape_under &&
                                                          shape_under.has_style?(Shape::STYLE::PROPAGATE_INTERACTIVE_CONNECTION)
          end

          # start the connection's creation process if possible
          if shape_under && shape_under.is_connection_accepted(shape_klass)
            if shape && @diagram.contains?(shape)
              @new_line_shape = shape
            else
              if shape
                err = @diagram.add_shape(shape, nil, Wx::DEFAULT_POSITION, INITIALIZE, DONT_SAVE_STATE)
              else
                err, shape = @diagram.create_shape(shape_info, DONT_SAVE_STATE)
              end
              @new_line_shape =  (err == ERRCODE::OK ? shape : nil)
            end
            return _start_interactive_connection(lpos, shape_under, shape_under.get_nearest_connection_point(lpos.to_real))
          else
            return ERRCODE::NOT_ACCEPTED
          end

        end
      end
      ERRCODE::INVALID_INPUT
    end

    # Abort interactive connection creation process
    def abort_interactive_connection
      return unless @diagram

      if @new_line_shape
        @diagram.remove_shape(@new_line_shape)
        @new_line_shape = nil
        on_connection_finished(nil)
      end
      @working_mode = MODE::READY
      refresh(false)
    end

    # Select all shapes in the canvas
    def select_all
      return unless @diagram

      shapes = @diagram.get_shapes

      unless shapes.empty?
        shapes.each { |shape| shape.select(true) }

        validate_selection(get_selected_shapes)

        hide_all_handles
        update_multiedit_size
        @shp_multi_edit.show(true)
        @shp_multi_edit.show_handles(true)

        refresh(false)
      end
    end

    # Deselect all shapes
    def deselect_all
      return unless @diagram

      @diagram.get_shapes.each { |shape| shape.select(false) }

      @shp_multi_edit.show(false)
    end

    # Hide handles of all shapes
    def hide_all_handles
      return unless @diagram

      @diagram.get_shapes.each { |shape| shape.show_handles(false) }
    end

    # Repaint the shape canvas.
    # @param [Boolean] erase true if the canvas should be erased before repainting
    # @param [Wx::Rect] rct Refreshed region (rectangle)
    def refresh_canvas(erase, rct)
      lpos = dp2lp(Wx::Point.new(0, 0))

      upd_rct = rct.inflate((20/@settings.scale).to_i, (20/@settings.scale).to_i)
      upd_rct.offset!(-lpos.x, -lpos.y)

      refresh_rect(Wx::Rect.new((upd_rct.x*@settings.scale).to_i,
                                (upd_rct.y*@settings.scale).to_i,
                                (upd_rct.width*@settings.scale).to_i,
                                (upd_rct.height*@settings.scale).to_i),
                   erase)
    end

    # Mark given rectangle as an invalidated one, i.e. as a rectangle which should
    # be refreshed (by using Wx::SF::ShapeCanvas::refresh_invalidated_rect).
    # @param [Wx::Rect] rct Rectangle to be invalidated
    def invalidate_rect(rct)
      if @invalidate_rect.nil?
        @invalidate_rect = rct.dup
      else
        @invalidate_rect.union!(rct)
      end
    end

    # Mark whole visible canvas portion as an invalidated rectangle.
    def invalidate_visible_rect
      invalidate_rect(dp2lp(get_client_rect))
    end

    # Refresh all canvas rectangles marked as invalidated.
    # @see Wx::SF::ShapeCanvas::invalidate_rect
    def refresh_invalidated_rect
      unless @invalidate_rect.nil? || @invalidate_rect.empty?
        refresh_canvas(false, @invalidate_rect)
        @invalidate_rect = nil
      end
    end

    # Show shapes shadows (only current diagram shapes are affected).
    #
    # The functions sets/unsets SHOW_SHADOW flag for all shapes currently included in the diagram.
    # @param [Boolean] show true if the shadow should be shown, otherwise false
    # @param [SHADOWMODE] style Shadow style
    # @see SHADOWMODE
    def show_shadows(show, style)
      return unless @diagram

      shapes = @diagram.get_shapes

      shapes.each do |shape|
        shape.remove_style(Shape::STYLE::SHOW_SHADOW) if show

        case style
        when SHADOWMODE::TOPMOST
          unless shape.get_parent_shape
            if show
              shape.add_style(Shape::STYLE::SHOW_SHADOW)
            else
              shape.remove_style(Shape::STYLE::SHOW_SHADOW)
            end
          end

        when SHADOWMODE::ALL
          if show
            shape.add_style(Shape::STYLE::SHOW_SHADOW)
          else
            shape.remove_style(Shape::STYLE::SHOW_SHADOW)
          end
        end
      end
    end

    if Wx.has_feature?(:USE_DRAG_AND_DROP)

      # Start Drag&Drop operation with shapes included in the given list.
      # @param [Array<Wx::SF::Shape>] shapes List of shapes which should be dragged
      # @param [Wx::Point] start A point where the dragging operation has started
      # @return [Wx::DragResult] Drag result
      def do_drag_drop(shapes, start = Wx::Point.new(-1, -1))
        return Wx::DragNone unless has_style?(STYLE::DND)

        @working_mode = MODE::DND

        result = Wx::DragNone

        validate_selection_for_clipboard(shapes, true)

        unless shapes.empty?
          deselect_all

          @dnd_started_here = true
          @dnd_started_at = start.to_point

          data_obj = Wx::SF::ShapeDataObject.new(shapes)

          dnd_src = if Wx::PLATFORM == 'WXGTK'
                      Wx::DropSource.new(data_obj, self, Wx::Icon(:page), Wx::Icon(:page), Wx::Icon(:page))
                    else
                      Wx::DropSource.new(data_obj)
                    end

          result = dnd_src.do_drag_drop(Wx::Drag_AllowMove)
          case result
          when Wx::DragResult::DragMove
            @diagram.remove_shapes(shapes)
          end

          @dnd_started_here = false

          restore_prev_positions

          move_shapes_from_negatives
          update_virtual_size

          save_canvas_state
          refresh(false)
        end

        @working_mode = MODE::READY

        result
      end

    end # if Wx.has_feature?(:USE_DRAG_AND_DROP)

    # Copy selected shapes to the clipboard
    def copy
      return unless has_style?(STYLE::CLIPBOARD)
      return unless @diagram

      # copy selected shapes to the clipboard
      Wx::Clipboard.open do |clipboard|
        lst_selection = get_selected_shapes

        validate_selection_for_clipboard(lst_selection,true)

        unless lst_selection.empty?
          data_obj = Wx::SF::ShapeDataObject.new(lst_selection)
          clipboard.place(data_obj)

          restore_prev_positions
        end
      end
    end

    # Copy selected shapes to the clipboard and remove them from the canvas
    def cut
      return unless has_style?(STYLE::CLIPBOARD)
      return unless @diagram

      copy

      clear_temporaries

      # remove selected shapes
      lst_selection = get_selected_shapes

      validate_selection_for_clipboard(lst_selection,false)

      unless lst_selection.empty?
        @diagram.remove_shapes(lst_selection)
        @shp_multi_edit.show(false)
        save_canvas_state
        refresh(false)
      end
    end

    # Paste shapes stored in the clipboard to the canvas
    def paste
      return unless has_style?(STYLE::CLIPBOARD)
      return unless @diagram

      Wx::Clipboard.open do |clipboard|
        # read data object from the clipboard
        data_obj = Wx::SF::ShapeDataObject.new
        if clipboard.fetch(data_obj)

          sdata = data_obj.get_data_here
          # deserialize shapes
          new_shapes = FIRM.deserialize(sdata)
          # add new shapes to diagram and remove those that are not accepted
          new_shapes.select! do |shape|
            ERRCODE::OK == @diagram.add_shape(shape, nil, shape.get_relative_position, INITIALIZE, DONT_SAVE_STATE)
          end

          # verify newly added shapes (may remove shapes from list)
          @diagram.send(:on_import, new_shapes)

          update_virtual_size # update for new shapes

          # call user-defined handler
          on_paste(new_shapes)

          save_canvas_state
          refresh(false)
        end
      end
    end

    # Perform Undo operation (if available)
    def undo
      return unless has_style?(STYLE::UNDOREDO)

      clear_temporaries

      restore_canvas_state(@canvas_history.restore_older_state)
      @shp_multi_edit.show(false)
    end

    # Perform Redo operation (if available)
    def redo
      return unless has_style?(STYLE::UNDOREDO)

      clear_temporaries

      restore_canvas_state(@canvas_history.restore_newer_state)
      @shp_multi_edit.show(false)
    end

    # Function returns true if some shapes can be copied to the clipboard (it means they are selected)
    # @return [Boolean]
    def can_copy
      return false unless has_style?(STYLE::CLIPBOARD)

      !get_selected_shapes.empty?
    end
    alias :can_copy? :can_copy

    # Function returns true if some shapes can be cut to the clipboard (it means they are selected)
    # @return [Boolean]
    def can_cut
      can_copy
    end
    alias :can_cut? :can_cut

    # Function returns true if some shapes can be copied from the clipboard to the canvas
    # (it means the clipboard contains stored shapes)
    # @return [Boolean]
    def can_paste
      return false unless has_style?(STYLE::CLIPBOARD)

      Wx::Clipboard.open do |clipboard|
        return clipboard.supported?(Wx::DataFormat.new(Wx::SF::ShapeDataObject::DataFormatID))
      end rescue false
    end
    alias :can_paste? :can_paste

    # Function returns true if undo operation can be done
    # @return [Boolean]
    def can_undo
      return false unless has_style?(STYLE::UNDOREDO)

      @canvas_history.can_undo
    end
    alias :can_undo? :can_undo

    # Function returns TRUE if Redo operation can be done
    # @return [Boolean]
    def can_redo
      return false unless has_style?(STYLE::UNDOREDO)

      @canvas_history.can_redo
    end
    alias :can_redo? :can_redo

    # Function returns true if align_selected function can be invoked (if more than
    # @return [Boolean]
    def can_align_selected
      @shp_multi_edit.visible? && @working_mode == MODE::READY
    end
    alias :can_align_selected? :can_align_selected

    # Save current canvas state (for Undo/Redo operations)
    def save_canvas_state
      return unless has_style?(STYLE::UNDOREDO)

      @canvas_history.save_canvas_state(@diagram.serialize)
    end

    # Clear all stored canvas states (no Undo/Redo operations will be available)
    def clear_canvas_history
      @canvas_history.clear
    end

    # Restores given canvas state (unless nil given)
    # @param [String,nil] state to restore
    def restore_canvas_state(state)
      return unless state
      set_diagram(FIRM.deserialize(state))
      update_virtual_size
      @diagram.set_modified
      refresh(false)
    end
    protected :restore_canvas_state

    # Restores current last saved canvas state.
    def restore_current_state
      return unless has_style?(STYLE::UNDOREDO)

      clear_temporaries

      restore_canvas_state(@canvas_history.current_state)
      @shp_multi_edit.show(false)
    end
    protected :restore_current_state

    # @!group Print methods

    # Print current canvas content.
    # @overload print(prompt = PROMPT)
    #   @param [Boolean] prompt If true (PROMPT) then the the native print dialog will be displayed before printing
    # @overload print(printout, prompt = PROMPT)
    #   @param [Wx::SF::Printout] printout user-defined printout object (inherited from Wx::SF::Printout class) for printing.
    #   @param [Boolean] prompt If true (PROMPT) then the the native print dialog will be displayed before printing
    # @see Wx::SF::Printout
    def print(*args)
      if args.first.is_a?(Wx::PRT::Printout)
        printout, prompt = args
      else
        printout = Printout.new('wxRuby SF Printout', self)
        prompt = args.shift
      end
      prompt = PROMPT if prompt.nil?

      print_dialog_data = Wx::PRT::PrintDialogData.new(ShapeCanvas.print_data)
      printer = Wx::PRT::Printer.new(print_dialog_data)

      deselect_all

      if !printer.print(self, printout, prompt)
        if Wx::PRT::Printer.get_last_error == Wx::PRT::PrinterError::PRINTER_ERROR
          Wx.message_box("There was a problem printing.\nPerhaps your current printer is not set correctly?",
                         'wxRuby SF Printing',
                         Wx::OK | Wx::ICON_ERROR)
        end
      else
        ShapeCanvas.print_data = printer.get_print_dialog_data.get_print_data
      end
    end

    # Show print preview.
    # @overload print_preview()
    # @overload print_preview(preview, printout = nil)
    #   @param [Wx::SF::Printout] preview user-defined printout object (inherited from Wx::SF::Printout class) used for print preview.
    #   @param [Wx::SF::Printout] printout user-defined printout class (inherited from Wx::SF::Printout class) used for printing.
    #   This parameter can be nil (in this case a print button will not be available in the print preview window).
    # @see Wx::SF::Printout
    def print_preview(*args)
      if args.empty?
        preview = Printout.new('wxRuby SF Preview', self)
        printout = Printout.new('wxRuby SF Printout', self)
      else
        preview, printout = args
      end

      deselect_all

      # Pass two printout objects: for preview, and possible printing.
      print_dialog_data = Wx::PRT::PrintDialogData.new(ShapeCanvas.print_data)
      prn_preview = Wx::PRT::PrintPreview.new(preview, printout, print_dialog_data)
      unless prn_preview.ok?
        Wx.message_box("There was a problem previewing.\nPerhaps your current printer is not set correctly?",
                       'wxRuby SF Previewing',
                       Wx::OK | Wx::ICON_ERROR)
        return
      end

      frame = Wx::PRT::PreviewFrame.new(prn_preview, self, 'wxRuby SF Print Preview', [100, 100], [800, 700])
      frame.centre(Wx::BOTH)
      frame.init
      frame.show
    end

    # Show page setup dialog for printing.
    def page_setup
      ShapeCanvas.page_setup_data.set_print_data(ShapeCanvas.print_data)

      Wx::PRT::PageSetupDialog(self, ShapeCanvas.page_setup_data) do |dlg|
        dlg.show_modal
        ShapeCanvas.print_data = dlg.get_page_setup_data.get_print_data
        ShapeCanvas.page_setup_data = dlg.get_page_setup_data
      end
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
    def dp2lp(arg)
      if arg.is_a?(Wx::Rect)
        x, y = calc_unscrolled_position(arg.x, arg.y)
        Wx::Rect.new((x/@settings.scale).to_i, (y/@settings.scale).to_i,
                     (arg.width/@settings.scale).to_i, (arg.height/@settings.scale).to_i)
      else
        arg = arg.to_point
        x, y = calc_unscrolled_position(arg.x, arg.y)
        Wx::Point.new((x/@settings.scale).to_i, (y/@settings.scale).to_i)
      end
    end

    # Convert logical position to device position.
    #
    # The function returns scrolled scaled canvas position.
    # @overload lp2dp(pos)
    #   @param [Wx::Point] pos Logical position (for example shape position)
    #   @return [Wx::Point] Device position
    # @overload lp2dp(rct)
    #   @param [Wx::Rect] rct Logical position (for example shape position)
    #   @return [Wx::Rect] Device position
    def lp2dp(arg)
      if arg.is_a?(Wx::Rect)
        x, y = calc_scrolled_position(arg.x, arg.y)
        Wx::Rect.new((x*@settings.scale).to_i, (y*@settings.scale).to_i,
                     (arg.width*@settings.scale).to_i, (arg.height*@settings.scale).to_i)
      else
        arg = arg.to_point
        x, y = calc_scrolled_position(arg.x, arg.y)
        Wx::Point.new((x*@settings.scale).to_i, (y*@settings.scale).to_i)
      end
    end

    # Search for any shape located at the (mouse cursor) position (result used by #get_shape_under_cursor)
    # @param [Wx::Point] lpos
    def update_shape_under_cursor_cache(lpos)
      sel_shape = unsel_shape = top_shape = nil
      sel_line = unsel_line = top_line = nil
      lpos = lpos.to_point

      @topmost_shape_under_cursor = nil

      @current_shapes.replace(@diagram.get_all_shapes) if @diagram

      @current_shapes.reverse_each do |shape|
        if shape.visible? && shape.active? && shape.contains?(lpos)
          if shape.is_a?(Wx::SF::LineShape)
            top_line ||= shape
            if shape.selected?
              sel_line ||= shape
            else
              unsel_line ||= shape
            end
          else
            top_shape ||= shape
            if shape.selected?
              sel_shape ||= shape
            elsif !shape.has_selected_parent?
              unsel_shape ||= shape
            end
          end
        end
      end

      # set reference to logically topmost selected and unselected shape under the mouse cursor
      @topmost_shape_under_cursor = top_line ? top_line : top_shape

      @selected_shape_under_cursor = sel_line ? sel_line : sel_shape

      @unselected_shape_under_cursor = unsel_line ? unsel_line : unsel_shape
    end

    # Get shape under current mouse cursor position (fast implementation - use everywhere
    # it is possible instead of much slower GetShapeAtPosition()).
    # @param [SEARCHMODE] mode Search mode
    # @return [Wx::SF::Shape,nil] shape if found, otherwise nil
    # @see SEARCHMODE, Wx::SF::ShapeCanvas#dp2lp, Wx::SF::ShapeCanvas#get_shape_at_position
    def get_shape_under_cursor(mode = SEARCHMODE::BOTH)
      case mode
      when SEARCHMODE::BOTH
        @topmost_shape_under_cursor
      when SEARCHMODE::SELECTED
        @selected_shape_under_cursor
      when SEARCHMODE::UNSELECTED
        @unselected_shape_under_cursor
      else
        nil
      end
    end

    # Get shape at given logical position
    # @param [Wx::Point] pos Logical position
    # @param [Integer] zorder Z-order of searched shape (useful if several shapes are located
    # at the given position)
    # @param [SEARCHMODE] mode Search mode
    # @return [Wx::SF::Shape,nil] shape if found, otherwise nil
    # @see SEARCHMODE, Wx::SF::ShapeCanvas#dp2lp, Wx::SF::ShapeCanvas#get_shape_under_cursor
    def get_shape_at_position(pos, zorder = 1, mode = SEARCHMODE::BOTH)
      return nil unless @diagram

      @diagram.get_shape_at_position(pos, zorder, mode)
    end

    # Get topmost handle at given position
    # @param [Wx::Point] pos Logical position
    # @return [Wx::SF::Shape::Handle,nil] shape handle if found, otherwise nil
    # @see Wx::SF::ShapeCanvas#dp2lp
    def get_topmost_handle_at_position(pos)
      return nil unless @diagram

      pos = pos.to_point
      # first test multiedit handles...
      if @shp_multi_edit.visible?
        @shp_multi_edit.handles.each do |handle|
          return handle if handle.visible? && handle.contains?(pos)
        end
      end

      # ... then test normal handles
      @diagram.get_shapes.each do |shape|
        # iterate through all shape's handles
        if shape.has_style?(Shape::STYLE::SIZE_CHANGE)
          shape.handles.each do |handle|
            return handle if handle.visible? && handle.contains?(pos)
          end
        end
      end

      nil
    end

    # Get list of all shapes located at given position
    # @param [Wx::Point] pos Logical position
    # @param [Array<Wx::SF::Shape>] shapes shape list where pointers to all found shapes will be stored
    # @return [Array<Wx::SF::Shape>] shapes shape list
    # @see Wx::SF::ShapeCanvas#dp2lp
    def get_shapes_at_position(pos, shapes = [])
      @diagram.get_shapes_at_position(pos, shapes) if @diagram
      shapes
    end

    # Get list of shapes located inside given rectangle
    # @param [Wx::Rect] rct Examined rectangle
    # @param [Array<Wx::SF::Shape>] shapes shape list where pointers to all found shapes will be stored
    # @return [Array<Wx::SF::Shape>] shapes shape list
    def get_shapes_inside(rct, shapes = [])
      @diagram.get_shapes_inside(rct, shapes) if @diagram
      shapes
    end

    # Get list of selected shapes.
    # @param [Array<Wx::SF::Shape>] selection shape list where pointers to all selected shapes will be stored
    # @return [Array<Wx::SF::Shape>] shapes shape list
    def get_selected_shapes(selection = [])
      return selection unless @diagram

      selection.clear
      @diagram.get_shapes.each do |shape|
        selection << shape if shape.selected?
      end
      selection
    end

    # Get box bounding all shapes in the canvas.
    # @return [Wx::Rect] Total bounding box
    def get_total_bounding_box
      virt_rct = nil
      if @diagram
        # calculate total bounding box (includes all shapes)
        @diagram.get_shapes.each_with_index do |shape, ix|
            if ix == 0
              virt_rct = shape.get_bounding_box
            else
              virt_rct.union!(shape.get_bounding_box)
            end
        end
      end
      virt_rct || Wx::Rect.new
    end

    # Get bounding box of all selected shapes.
    # @return [Wx::Rect] Selection bounding box
    def get_selection_bb
      bb_rct = nil
      # get selected shapes
      get_selected_shapes.each do |shape|
        bb_rct = shape.get_complete_bounding_box(bb_rct,
                                                 Shape::BBMODE::SELF | Shape::BBMODE::CHILDREN |
                                                   Shape::BBMODE::CONNECTIONS | Shape::BBMODE::SHADOW)
      end
      bb_rct || Wx::Rect.new
    end

    # Align selected shapes in given directions.
    #
    # Shapes will be aligned according to most far shape in appropriate direction.
    # @param [HALIGN] halign Horizontal alignment
    # @param [VALIGN] valign Vertical alignment
    def align_selected(halign, valign)
      cnt = 0
      min_pos = max_pos = nil

      lst_selection = get_selected_shapes

      upd_rct = get_selection_bb
      upd_rct.inflate!(DEFAULT_ME_OFFSET, DEFAULT_ME_OFFSET)

      # find most distant position
      lst_selection.each do |shape|
        unless shape.is_a?(LineShape)
          pos = shape.get_absolute_position
          shape_bb = shape.get_bounding_box

          if cnt == 0
            min_pos = pos.dup
            max_pos = Wx::RealPoint.new(pos.x + shape_bb.width, pos.y + shape_bb.height)
          else
            min_pos.x = pos.x if pos.x < min_pos.x
            min_pos.y = pos.y if pos.y < min_pos.y
            max_pos.x = pos.x + shape_bb.width if (pos.x + shape_bb.width) > max_pos.x
            max_pos.y = pos.y + shape_bb.height if (pos.y + shape_bb.height) > max_pos.y
          end

          cnt += 1
        end
      end

      # if only one non-line shape is in the selection then alignment has no sense so exit...
      return if cnt < 2

      # set new positions
      lst_selection.each do |shape|
        unless shape.is_a?(LineShape)
          pos = shape.get_absolute_position
          shape_bb = shape.get_bounding_box

          case halign
          when HALIGN::LEFT
            shape.move_to(min_pos.x, pos.y)

          when HALIGN::RIGHT
            shape.move_to(max_pos.x - shape_bb.width, pos.y)

          when HALIGN::CENTER
            shape.move_to((max_pos.x + min_pos.x)/2 - shape_bb.width/2, pos.y)
          end

          case valign
          when VALIGN::TOP
            shape.move_to(pos.x, min_pos.y)

          when VALIGN::BOTTOM
            shape.move_to(pos.x, max_pos.y - shape_bb.height)

          when VALIGN::MIDDLE
            shape.move_to(pos.x, (max_pos.y + min_pos.y)/2 - shape_bb.height/2)
          end

          # update the shape and its parent
          shape.update
          parent = shape.get_parent_shape
          parent.update if parent
        end
      end

      unless upd_rct.empty?
        update_multiedit_size
        save_canvas_state
        refresh_canvas(false, upd_rct)
      end
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
      @settings.grid_size = grid.to_size
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
      @settings.shadow_offset = offset.to_real_point
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
      return unless @diagram

      if scale != 1.0
        # query shapes
        msg = ''
        unless _query_canvas_change(CHANGE::SET_SCALE, msg)
          Wx.message_box("Cannot change scale of shape canvas: #{msg}.", 'wxRuby ShapeFramework', Wx::ICON_WARNING | Wx::OK)
          scale = 1.0
        end
      end

      @settings.scale = scale != 0.0 ? scale : 1.0

      # inform shapes
      _notify_canvas_change(CHANGE::RESCALED)

      update_virtual_size
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
      phys_rct = get_client_size
      virt_rct = get_total_bounding_box

      hz = phys_rct.width.to_f / virt_rct.right
      vz = phys_rct.height.to_f / virt_rct.bottom

      if hz < vz
        set_scale(hz < 1 ? hz : 1.0)
      else
        set_scale(vz < 1 ? vz : 1.0)
      end
    end

    # Scroll the shape canvas so the given shape will be located in its center.
    # @param [Wx::SF::Shape] shape Pointer to focused shape
    def scroll_to_shape(shape)
      if shape
        ux, uy = get_scroll_pixels_per_unit
        sz_canvas = get_client_size
        pt_pos = shape.center

        scroll(((pt_pos.x * @settings.scale) - sz_canvas.x/2)/ux, ((pt_pos.y * @settings.scale) - sz_canvas.y/2)/uy)
      end
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
      return unless @diagram

      @settings.common_hover_color = col

      # update Hover color in all existing shapes
      @diagram.get_shapes.each { |shape| shape.set_hover_colour(col) }
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
      pos = pos.to_point
      if has_style?(STYLE::GRID_USE)
        Wx::Point.new(pos.x / @settings.grid_size.x * @settings.grid_size.x,
          pos.y / @settings.grid_size.y * @settings.grid_size.y)
      else
        pos
      end
    end

	  # Update size of multi selection rectangle
    def update_multiedit_size
      # calculate bounding box
      union_rct = nil
      get_selected_shapes.each_with_index do |shape, ix|
        if ix == 0
          union_rct = shape.get_bounding_box
        else
          union_rct.union!(shape.get_bounding_box)
        end
      end
      union_rct ||= Wx::Rect.new
      union_rct.inflate!([DEFAULT_ME_OFFSET, DEFAULT_ME_OFFSET])

      # draw rectangle
      @shp_multi_edit.set_relative_position(Wx::RealPoint.new(union_rct.x.to_f, union_rct.y.to_f))
      @shp_multi_edit.set_rect_size(Wx::RealPoint.new(union_rct.width.to_f, union_rct.height.to_f))
    end

	  # Update scroll window virtual size so it can display all shape canvas
    def update_virtual_size
      virt_rct = get_total_bounding_box

      # allow user to modify calculated virtual canvas size
      on_update_virtual_size(virt_rct)

      # update virtual area of the scrolled window if necessary
      if virt_rct.empty?
        set_virtual_size(500, 500)
      else
        set_virtual_size((virt_rct.right*@settings.scale).to_i, (virt_rct.bottom*@settings.scale).to_i)
      end
      _notify_canvas_change(CHANGE::VIRTUAL_SIZE)
    end

	  # Move all shapes so none of it will be located in negative position
    def move_shapes_from_negatives
      @diagram.move_shapes_from_negatives if @diagram
    end

	  # Center diagram in accordance to the shape canvas extent.
    def center_shapes
      rct_prev_bb = get_total_bounding_box

      rct_bb = rct_prev_bb.center_in(Wx::Rect.new(Wx::Point.new(0, 0), get_size))

      dx = (rct_bb.left - rct_prev_bb.left).to_f
      dy = (rct_bb.top - rct_prev_bb.top).to_f

      @current_shapes.each do |shape|
        shape.move_by(dx, dy) unless shape.get_parent_shape
      end

      move_shapes_from_negatives
    end
    
    # Validate selection (remove redundantly selected shapes etc...).
    # @param [Array<Wx::SF::Shape>] selection List of selected shapes that should be validated
    def validate_selection(selection)
      return unless @diagram

      # find child shapes that have parents in the list and deselect and remove those
      # so we only have regular toplevel shapes and orphaned child shapes
      selection.select! do |shape|
        if selection.include?(shape.get_parent_shape)
          shape.select(false)
          false
        else
          true
        end
      end

      # move selected (toplevel) shapes to the back of the shapes list in the diagram
      # this gives a higher Z-order so they will float on top of other shapes when dragging
      selection.each do |shape|
        # in case of child shapes find the toplevel parent it belongs to and move that one
        shape = shape.get_parent_shape while shape.get_parent_shape
        @diagram.move_to_end(shape)
      end
    end

    # Draws shapes intersecting the update region
    def draw_shape_updates(dc, upd_rct, lst_to_draw, exclude_selected = false)
      lst_selected = exclude_selected ? [] : nil
      lst_lines_to_draw = []
      # draw unselected non line-based shapes first...
      lst_to_draw.each do |shape|
        if exclude_selected && (shape.selected? || shape.has_selected_parent?)
          lst_selected << shape
        else
          if !shape.is_a?(LineShape) || shape.stand_alone?
            if shape.intersects?(upd_rct)
              parent_shape = shape.get_parent_shape
              if parent_shape
                shape.draw(dc, WITHOUTCHILDREN) if !parent_shape.is_a?(LineShape) || parent_shape.stand_alone?
              else
                shape.draw(dc, WITHOUTCHILDREN)
              end
            end
          else
            lst_lines_to_draw << shape
          end
        end
      end

      # ... and draw connections
      bb_rct = nil
      lst_lines_to_draw.each do |line|
        bb_rct = line.get_complete_bounding_box(bb_rct, Shape::BBMODE::SELF | Shape::BBMODE::CHILDREN | Shape::BBMODE::SHADOW)
        line.draw(dc, line.get_line_mode == LineShape::LINEMODE::READY) if bb_rct.intersects(upd_rct)
      end
      lst_selected
    end
    private :draw_shape_updates

	  # Function responsible for drawing of the canvas's content to given DC. The default
    # implementation draws actual objects managed by assigned diagram manager.
    # @param [Wx::DC] dc device context where the shapes will be drawn to
    # @param [Boolean] from_paint Set the argument to true if the dc argument refers to the Wx::PaintDC instance
    # or derived classes (i.e. the function is called as a response to Wx::EVT_PAINT event)
    def draw_content(dc, from_paint)
      return unless @diagram

      if from_paint
        # get all existing shapes
        lst_to_draw = @diagram.get_shapes(Shape, Shape::SEARCHMODE::DFS)

        upd_rct = nil
        # get the update rect list
        Wx::RegionIterator.for_region(get_update_region) do |region_it|
          # combine updated rectangles
          region_it.each do |rct|
            if upd_rct.nil?
              upd_rct = dp2lp(rct.inflate(5, 5))
            else
              upd_rct.union!(dp2lp(rct.inflate(5, 5)))
            end
          end
        end
        upd_rct ||= Wx::Rect.new

        if @working_mode == MODE::SHAPEMOVE
          # draw unselected shapes first and filter and return selected shapes
          lst_selected = draw_shape_updates(dc, upd_rct, lst_to_draw, true)

          # ... and now draw the selected shapes being moved
          draw_shape_updates(dc, upd_rct, lst_selected)
        else
          draw_shape_updates(dc, upd_rct, lst_to_draw)
        end

        # draw multiselection if necessary
        @shp_selection.draw(dc) if @shp_selection.visible?
        @shp_multi_edit.draw(dc) if @shp_multi_edit.visible?
      else
        # draw parent shapes (children are processed by parent objects)
        @diagram.get_top_shapes.each do |shape|
          shape.draw(dc) if !shape.is_a?(LineShape) || shape.stand_alone?
        end

        # draw connections
        @diagram.get_top_shapes.each do |shape|
          shape.draw(dc) if shape.is_a?(LineShape) && !shape.stand_alone?
        end
      end
    end

	  # Function responsible for drawing of the canvas's background to given DC. The default
    # implementation draws canvas background and grid.
    # @param [Wx::DC] dc device context where the shapes will be drawn to
    # @param [Boolean] _from_paint Set the argument to true if the dc argument refers to the Wx::PaintDC instance
    # or derived classes (i.e. the function is called as a response to Wx::EVT_PAINT event)
    def draw_background(dc, _from_paint)
      # erase background
      if has_style?(STYLE::GRADIENT_BACKGROUND)
        bcg_size = @settings.grid_size + get_virtual_size
        if @settings.scale != 1.0
          dc.gradient_fill_linear(Wx::Rect.new([0, 0], [(bcg_size.x/@settings.scale).to_i, (bcg_size.y/@settings.scale).to_i]),
                                  @settings.gradient_from, @settings.gradient_to, Wx::SOUTH)
        else
          dc.gradient_fill_linear(Wx::Rect.new(Wx::Point.new(0, 0),  bcg_size),
                                  @settings.gradient_from, @settings.gradient_to, Wx::SOUTH)
        end
      else
        dc.set_background(Wx::Brush.new(@settings.background_color))
        dc.clear
      end

      # show grid
      if has_style?(STYLE::GRID_SHOW)
        linedist = @settings.grid_size.x * @settings.grid_line_mult

        if (linedist * @settings.scale) > 3.0
          grid_rct = Wx::Rect.new([0, 0], @settings.grid_size + get_virtual_size)
          max_x = (grid_rct.right/@settings.scale).to_i
          max_y = (grid_rct.bottom/@settings.scale).to_i

          dc.set_pen(Wx::Pen.new(@settings.grid_color, 1, @settings.grid_style))
          (grid_rct.left..max_x).step(linedist) do |x|
            dc.draw_line(x, 0, x, max_y)
          end
          (grid_rct.top..max_y).step(linedist) do |y|
            dc.draw_line(0, y, max_x, y)
          end
        end
      end
    end

	  # Function responsible for drawing of the canvas's foreground to given DC. The default
    # do nothing.
    # @param [Wx::DC] _dc device context where the shapes will be drawn to
    # @param [Boolean] _from_paint Set the argument to true if the dc argument refers to the Wx::PaintDC instance
    # or derived classes (i.e. the function is called as a response to Wx::EVT_PAINT event)
    def draw_foreground(_dc, _from_paint)
      # do nothing here...
    end

    # Get reference to multiselection box
    # @return [Wx::SF::MultiSelRect] multiselection box object
    def get_multiselection_box
      @shp_multi_edit
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
      # HINT: override it for custom actions...
      return unless @diagram

      _notify_canvas_change(CHANGE::FOCUS)
      set_focus
    
      lpos = dp2lp(event.get_position)
    
      @can_save_state_on_mouse_up = false
    
      case @working_mode
      when MODE::READY
        @selected_handle = get_topmost_handle_at_position(lpos)

        if event.control_down && event.shift_down
          @selection_mode = SELECTIONMODE::REMOVE
        elsif event.shift_down
          @selection_mode = SELECTIONMODE::ADD
        else
          @selection_mode = SELECTIONMODE::NORMAL
        end

        if @selected_handle.nil?
          selected_shape = get_shape_at_position(lpos)

          selected_top_shape = selected_shape
          while selected_top_shape && selected_top_shape.has_style?(Shape::STYLE::PROPAGATE_SELECTION)
            selected_top_shape = selected_top_shape.get_parent_shape
          end

          if selected_shape
            # perform selection
            lst_selection = get_selected_shapes

            if @selection_mode == SELECTIONMODE::NORMAL
              save_canvas_state if @canvas_history.empty?
            end

            # cancel previous selections if necessary...
            if @selection_mode == SELECTIONMODE::NORMAL && (selected_top_shape.nil? || !lst_selection.include?(selected_top_shape))
              deselect_all
            end
            selected_top_shape.select(@selection_mode != SELECTIONMODE::REMOVE) if selected_top_shape

            get_selected_shapes(lst_selection)

            # remove child shapes from the selection
            validate_selection(lst_selection)

            if lst_selection.size > 1
              hide_all_handles
            elsif @selection_mode == SELECTIONMODE::REMOVE && lst_selection.size == 1
              lst_selection.first.select(true)
            end

            fit_pos = fit_position_to_grid(lpos)

            # call user defined actions
            selected_shape.on_left_click(fit_pos)

            # inform selected shapes about begin of dragging...
            lst_connections = []

            lst_selection.each do |shape|
              shape.send(:_on_begin_drag, fit_pos)

              # inform also connections assigned to the shape and its children
              lst_connections.clear
              append_assigned_connections(shape, lst_connections, true)

              lst_connections.each do |line|
                line.send(:_on_begin_drag, fit_pos)
              end
            end

            if @selection_mode == SELECTIONMODE::NORMAL
              @shp_multi_edit.show(false)
              @working_mode = MODE::SHAPEMOVE
            else
              if lst_selection.size > 1
                @shp_multi_edit.show(true)
                @shp_multi_edit.show_handles(true)
              else
                @shp_multi_edit.show(false)
              end
              @working_mode = MODE::READY
            end
          else
            if has_style?(STYLE::MULTI_SELECTION)
              deselect_all if @selection_mode == SELECTIONMODE::NORMAL
              @selection_start = Wx::RealPoint.new(lpos.x, lpos.y)
              @shp_selection.show(true)
              @shp_selection.show_handles(false)
              @shp_selection.set_relative_position(@selection_start)
              @shp_selection.set_rect_size(Wx::RealPoint.new(0, 0))
              @working_mode = MODE::MULTISELECTION
            else
              deselect_all
              @working_mode = MODE::READY
            end
          end

          # update canvas
          invalidate_visible_rect
        else
          save_canvas_state if @canvas_history.empty?
          if @selected_handle.get_parent_shape == @shp_multi_edit
            if has_style?(STYLE::MULTI_SIZE_CHANGE)
              @working_mode = MODE::MULTIHANDLEMOVE
            else
              @working_mode = MODE::READY
            end
          else
            @working_mode = MODE::HANDLEMOVE
            case @selected_handle.get_type
            when Shape::Handle::TYPE::LINESTART
              line = @selected_handle.get_parent_shape
              line.send(:set_line_mode, LineShape::LINEMODE::SRCCHANGE)
              line.send(:set_unfinished_point, lpos)

            when Shape::Handle::TYPE::LINEEND
              line = @selected_handle.get_parent_shape
              line.send(:set_line_mode, LineShape::LINEMODE::TRGCHANGE)
              line.send(:set_unfinished_point, lpos)
            end
          end
          @selected_handle.send(:_on_begin_drag, fit_position_to_grid(lpos))
        end

      when MODE::CREATECONNECTION
        # update the line shape being created
        if @new_line_shape
          shape_under = get_shape_under_cursor
          # propagate request for interactive connection if requested
          while shape_under && shape_under.has_style?(Shape::STYLE::PROPAGATE_INTERACTIVE_CONNECTION)
            shape_under = shape_under.get_parent_shape
          end
          # finish connection's creation process if possible
          if shape_under && !event.control_down
            if @new_line_shape.get_trg_shape.nil? && (shape_under != @new_line_shape) &&
              (shape_under.is_connection_accepted(@new_line_shape.class))
              # find out whether the target shape can be connected to the source shape
              source_shape = @new_line_shape.get_src_shape

              if source_shape &&
                  shape_under.is_src_neighbour_accepted(source_shape.class) &&
                  source_shape.is_trg_neighbour_accepted(shape_under.class)
                @new_line_shape.set_trg_shape(shape_under)
                @new_line_shape.set_ending_connection_point(shape_under.get_nearest_connection_point(lpos.to_real))

                # inform user that the line is completed
                case on_pre_connection_finished(@new_line_shape)
                when PRECON_FINISH_STATE::OK
                when PRECON_FINISH_STATE::FAILED_AND_CANCEL_LINE
                  @new_line_shape.set_trg_shape(nil)
                  @diagram.remove_shape(@new_line_shape)
                  @working_mode = MODE::READY
                  @new_line_shape = nil
                  return
                when PRECON_FINISH_STATE::FAILED_AND_CONTINUE_EDIT
                  @new_line_shape.set_trg_shape(nil)
                  return
                end
                @new_line_shape.create_handles

                # switch off the "under-construction" mode
                @new_line_shape.send(:set_line_mode, LineShape::LINEMODE::READY)

                on_connection_finished(@new_line_shape)

                @new_line_shape.update
                @new_line_shape.refresh(DELAYED)

                @working_mode = MODE::READY
                @new_line_shape = nil

                save_canvas_state
              end
            end
          else
            if @new_line_shape.get_src_shape
              fit_pos = fit_position_to_grid(lpos)
              @new_line_shape.get_control_points << Wx::RealPoint.new(fit_pos.x, fit_pos.y)
            end
          end
        end

      else
        @working_mode = MODE::READY
      end
    
      refresh_invalidated_rect
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
      # HINT: override it for custom actions...

      _notify_canvas_change(CHANGE::FOCUS)
      set_focus

      lpos = dp2lp(event.get_position)

      if @working_mode == MODE::READY
        shape = get_shape_under_cursor
        if shape
          shape.on_left_double_click(lpos)

          # double click onto a line shape always change its set of
          # control points so the canvas state should be saved now...
          save_canvas_state if shape.is_a?(LineShape)
        end
      end

      refresh_invalidated_rect
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
      # HINT: override it for custom actions...
      lpos = dp2lp(event.get_position)
    
      case @working_mode
      when MODE::MULTIHANDLEMOVE, MODE::HANDLEMOVE
        # resize parent shape to fit all its children if necessary
        if @selected_handle.get_parent_shape.get_parent_shape
          @selected_handle.get_parent_shape.get_parent_shape.update
        end

        # if the handle is line handle then return the line to normal state
        # and re-assign line's source/target shape
        case @selected_handle.get_type
        when Shape::Handle::TYPE::LINESTART, Shape::Handle::TYPE::LINEEND
          line = @selected_handle.get_parent_shape
          line.send(:set_line_mode, LineShape::LINEMODE::READY)

          parent_shape = get_shape_under_cursor

          if parent_shape && (parent_shape != line) && (parent_shape.is_connection_accepted(line.class))
            if @selected_handle.get_type == Shape::Handle::TYPE::LINESTART
              trg_shape = line.get_trg_shape
              if trg_shape && parent_shape.is_trg_neighbour_accepted(trg_shape.class)
                line.set_src_shape(parent_shape)
              end
            else
              src_shape = line.get_src_shape
              if src_shape && parent_shape.is_src_neighbour_accepted(src_shape.class)
                line.set_trg_shape(parent_shape)
              end
            end
          end
        end

        @selected_handle.send(:_on_end_drag, lpos)

        @selected_handle = nil
        save_canvas_state if @can_save_state_on_mouse_up 

      when MODE::SHAPEMOVE
        lst_selection = get_selected_shapes
  
        lst_selection.each do |shape|
          # notify shape
          shape.send(:_on_end_drag, lpos)
          # reparent based on new position
          reparent_dropped_shape(shape, lpos)
        end
  
        if lst_selection.size>1
          @shp_multi_edit.show(true)
          @shp_multi_edit.show_handles(true)
        else
          @shp_multi_edit.show(false)
        end
  
        move_shapes_from_negatives

        save_canvas_state if @can_save_state_on_mouse_up
    
      when MODE::MULTISELECTION
        lst_selection = get_selected_shapes

        sel_rect = @shp_selection.get_bounding_box
        @current_shapes.each do |shape|
          if shape.active? && sel_rect.contains?(shape.get_bounding_box)
            shape = shape.get_parent_shape while shape && shape.has_style?(Shape::STYLE::PROPAGATE_SELECTION)
            if shape
              shape.select(@selection_mode != SELECTIONMODE::REMOVE)
              shape_pos = lst_selection.index(shape)
              if @selection_mode != SELECTIONMODE::REMOVE && shape_pos.nil?
                lst_selection << shape
              elsif @selection_mode == SELECTIONMODE::REMOVE && shape_pos
                lst_selection.delete_at(shape_pos)
              end
            end
          end
        end

        validate_selection(lst_selection)

        if lst_selection.empty?
          @shp_multi_edit.show(false)
        else
          hide_all_handles
          @shp_multi_edit.show(true)
          @shp_multi_edit.show_handles(true)
        end

        @shp_selection.show(false)
      end
    
      if @working_mode != MODE::CREATECONNECTION
        # update canvas
        @working_mode = MODE::READY
        update_multiedit_size
        update_virtual_size
        refresh(false)
      else
        refresh_invalidated_rect
      end
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
      # HINT: override it for custom actions...

      _notify_canvas_change(CHANGE::FOCUS)
      set_focus
    
      lpos = dp2lp(event.get_position)
    
      if @working_mode == MODE::READY
        deselect_all
  
        shape = get_shape_under_cursor
        if shape
          shape.select(true)
          shape.on_right_click(lpos)
        end
      end
    
      refresh(false)
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
      # HINT: override it for custom actions...

      _notify_canvas_change(CHANGE::FOCUS)
      set_focus
    
      lpos = dp2lp(event.get_position)
    
      if @working_mode == MODE::READY
        shape = get_shape_under_cursor
        shape.on_right_double_click(lpos) if shape
      end

      refresh_invalidated_rect
    end

    # Event handler called when the right mouse button is released.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param [Wx::MouseEvent] _event Mouse event
    # @see _on_right_up
    def on_right_up(_event)
      # HINT: override it for custom actions...
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
      # HINT: override it for custom actions...
      return unless @diagram
    
      lpos = dp2lp(event.get_position)
    
      case @working_mode
      when MODE::READY, MODE::CREATECONNECTION
        unless event.dragging
          # send event to multiedit shape
          @shp_multi_edit.send(:_on_mouse_move, lpos) if @shp_multi_edit.visible?

          # send event to all user shapes
          @current_shapes.each { |shape| shape.send(:_on_mouse_move, lpos) }

          # update unfinished line if any
          if @new_line_shape
            line_rct = @new_line_shape.get_complete_bounding_box(nil, Shape::BBMODE::SELF | Shape::BBMODE::CHILDREN)

            @new_line_shape.send(:set_unfinished_point, fit_position_to_grid(lpos))
            @new_line_shape.update

            line_rct = @new_line_shape.get_complete_bounding_box(line_rct, Shape::BBMODE::SELF | Shape::BBMODE::CHILDREN)

            invalidate_rect(line_rct)
          end
        end

      when MODE::HANDLEMOVE, MODE::MULTIHANDLEMOVE, MODE::SHAPEMOVE
        if @working_mode != MODE::SHAPEMOVE
          if event.dragging
            @selected_handle.send(:_on_dragging, fit_position_to_grid(lpos)) if @selected_handle
            update_multiedit_size if @working_mode == MODE::MULTIHANDLEMOVE
            @can_save_state_on_mouse_up = true
          else
            @selected_handle.send(:_on_end_drag, lpos) if @selected_handle
            @selected_handle = nil
            @working_mode = MODE::READY
          end
        end
        unless @working_mode == MODE::MULTIHANDLEMOVE
          if event.dragging
            if has_style?(STYLE::GRID_USE)
              return if (event.get_position.x - @prev_mouse_pos.x).abs < @settings.grid_size.x &&
                        (event.get_position.y - @prev_mouse_pos.y).abs < @settings.grid_size.y
            end
            @prev_mouse_pos = event.get_position

            if event.control_down || event.shift_down
              lst_selection = get_selected_shapes
              deselect_all
              if Wx.has_feature?(:USE_DRAG_AND_DROP)
                do_drag_drop(lst_selection, lpos)
              end
            else
              lst_connections = []
              @current_shapes.each do |shape|
                if shape.selected? && @working_mode == MODE::SHAPEMOVE
                  shape.send(:_on_dragging, fit_position_to_grid(lpos))

                  # move also connections assigned to this shape and its children
                  lst_connections.clear

                  append_assigned_connections(shape, lst_connections,true)

                  lst_connections.each { |line| line.send(:_on_dragging, fit_position_to_grid(lpos)) }

                  # update connections assigned to this shape
                  lst_connections = @diagram.get_assigned_connections(shape, LineShape, Shape::CONNECTMODE::BOTH)
                  lst_connections.each { |line| line.update }
                else
                  shape.send(:_on_mouse_move, lpos)
                end
              end

              @can_save_state_on_mouse_up = true
            end
          else
            @working_mode = MODE::READY
          end
        end

      when MODE::MULTISELECTION
        selection_pos = Wx::RealPoint.new(*@selection_start.to_ary)
        selection_size = Wx::RealPoint.new(lpos.x - @selection_start.x, lpos.y - @selection_start.y)
        if selection_size.x < 0
          selection_pos.x += selection_size.x
          selection_size.x = -selection_size.x
        end
        if selection_size.y < 0
          selection_pos.y += selection_size.y
          selection_size.y = -selection_size.y
        end
        @shp_selection.set_relative_position(selection_pos)
        @shp_selection.set_rect_size(selection_size)

        invalidate_visible_rect
      end
    
      refresh_invalidated_rect
    end

    # Event handler called when the mouse wheel position is changed.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework and provides basic functionality
    # needed for proper management of displayed shape. It is necessary to call
    # this function from overridden methods if the default canvas behaviour
    # should be preserved.
    # @param [Wx::MouseEvent] event Mouse event
    def on_mouse_wheel(event)
      # HINT: override it for custom actions...
    
      if event.control_down
        scale = get_scale
        scale += (event.get_wheel_rotation/(event.get_wheel_delta*10)).to_f

        scale = @settings.min_scale if scale < @settings.min_scale
        scale = @settings.max_scale if scale > @settings.max_scale
    
        set_scale(scale)
        refresh(false)
      end
    
      event.skip
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
      # HINT: override it for custom actions...
      return unless @diagram

      lst_selection = get_selected_shapes
    
      case event.get_key_code
      when Wx::K_DELETE
        # send event to selected shapes
        lst_selection.delete_if do |shape|
          if shape.has_style?(Shape::STYLE::PROCESS_DEL)
            shape.send(:_on_key, event.get_key_code)
            true
          else
            false
          end
        end

        clear_temporaries

        # delete selected shapes
        @diagram.remove_shapes(lst_selection)
        @shp_multi_edit.show(false)
        save_canvas_state
        refresh(false)

      when Wx::K_ESCAPE
        case @working_mode
        when MODE::CREATECONNECTION
          abort_interactive_connection

        when MODE::HANDLEMOVE
          if @selected_handle && @selected_handle.get_parent_shape.is_a?(LineShape)
            @selected_handle.send(:_on_end_drag, Wx::Point.new(0, 0))

            line = @selected_handle.get_parent_shape
            line.send(:set_line_mode, LineShape::LINEMODE::READY)
            @selected_handle = nil
          end
          restore_current_state

        when MODE::MULTIHANDLEMOVE
          restore_current_state

        when MODE::SHAPEMOVE
          restore_current_state

        else
          # send event to selected shapes
          lst_selection.each { |shape| shape.send(:_on_key, event.get_key_code) }
        end
        @working_mode = MODE::READY
        refresh(false)

      when Wx::K_LEFT, Wx::K_RIGHT, Wx::K_UP, Wx::K_DOWN
          lst_connections = []
          lst_selection.each do |shape|
            shape.send(:_on_key, event.get_key_code)
    
            # inform also connections assigned to this shape
            lst_connections.clear
            append_assigned_connections(shape, lst_connections, true)
    
            lst_connections.each do |line|
              line.send(:_on_key, event.get_key_code) unless line.selected?
            end
          end
    
          # send the event to multiedit ctrl if displayed
          @shp_multi_edit.send(:_on_key, event.get_key_code) if @shp_multi_edit.visible?

          refresh_invalidated_rect
          save_canvas_state

      else
        lst_selection.each { |shape| shape.send(:_on_key, event.get_key_code) }
        update_multiedit_size if @shp_multi_edit.visible?
      end
    end

    # Event handler called when any editable text shape is changed.
    # The function can be overridden if necessary.
    # The function is called by the framework and its default implementation
    # generates Wx::SF::EVT_SF_TEXT_CHANGE event.
    # @param [Wx::SF::EditTextShape] shape Changed Wx::SF::EditTextShape object
    # @see Wx::SF::EditTextShape#edit_label
    # @see Wx::SF::ShapeTextEvent
    def on_text_change(shape)
      # HINT: override it for custom actions...
    
      # ... standard implementation generates the Wx::SF::EVT_SF_TEXT_CHANGE event.
      id = shape ? shape.object_id : nil

      event = ShapeTextEvent.new(Wx::SF::EVT_SF_TEXT_CHANGE, id)
      event.set_shape(shape)
      event.set_text(shape.get_text)
      process_event(event)
    end

    # Event handler called after (successful or cancelled) connection creation. The function
    # can be overridden if necessary. The default implementation
    # generates Wx::SF::EVT_SF_LINE_DONE event.
    # @param [Wx::SF::LineShape,nil] connection new connection object (nil if cancelled)
    # @see start_interactive_connection
    # @see Wx::SF::ShapeEvent
    def on_connection_finished(connection)
      # HINT: override to perform user-defined actions...
    
      # ... standard implementation generates the Wx::SF::EVT_SF_LINE_DONE event.
      id = connection ? connection.object_id : -1

      event = ShapeEvent.new(Wx::SF::EVT_SF_LINE_DONE, id)
      event.set_shape(connection)
      process_event(event)
    end

    # Event handler called after successful connection creation in
    # order to allow developer to perform some kind of checks
    # before the connection is really added to the diagram. The function
    # can be overridden if necessary. The default implementation
    # generates Wx::SF::EVT_SF_LINE_DONE event.
    # @param [Wx::SF::LineShape] connection new connection object
    # @return [PRECON_FINISH_STATE] PRECONNECTIONFINISHEDSTATE::OK if the connection is accepted, otherwise
    # if the generated event has been vetoed the connection creation is cancelled
    # @see start_interactive_connection
    # @see Wx::SF::ShapeEvent
    def on_pre_connection_finished(connection)
      # HINT: override to perform user-defined actions...
    
      # ... standard implementation generates the Wx::SF::EVT_SF_LINE_DONE event.
      id = connection ? connection.object_id : -1
    
      event = ShapeEvent.new(Wx::SF::EVT_SF_LINE_BEFORE_DONE, id)
      event.set_shape(connection)
      process_event(event)

      return PRECON_FINISH_STATE::FAILED_AND_CANCEL_LINE if event.vetoed?

      PRECON_FINISH_STATE::OK
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
      # HINT: override it for custom actions...
    
      # ... standard implementation generates the Wx::SF::EVT_SF_ON_DROP event.
      return unless has_style?(STYLE::DND)
    
      # create the drop event and process it
      event = ShapeDropEvent.new(Wx::SF::EVT_SF_ON_DROP, x, y, self, deflt, Wx::ID_ANY)
      event.set_dropped_shapes(dropped)
      process_event(event)
    end

    end

    # Event handler called by the framework after pasting of shapes
    # from the clipboard to the canvas. The default implementation
    # generates Wx::SF::EVT_SF_ON_PASTE event.
    # @param [Array<Wx::SF::Shape>] pasted a list containing the pasted data
    # @see Wx::SF::ShapeCanvas#paste
    # @see Wx::SF::ShapePasteEvent
    def on_paste(pasted)
      # HINT: override it for custom actions...
    
      # ... standard implementation generates the Wx::SF::EVT_SF_ON_PASTE event.
      return unless has_style?(STYLE::CLIPBOARD)
    
      # create the drop event and process it
      event = ShapePasteEvent.new(Wx::SF::EVT_SF_ON_PASTE, self, Wx::ID_ANY)
      event.set_pasted_shapes(pasted)
      process_event(event)
    end

    # Event handler called if canvas virtual size is going to be updated.
    # The default implementation does nothing but the function can be overridden by
    # a user to modify calculated virtual canvas size.
    # @param [Wx::Rect] _virtrct Calculated canvas virtual size
    def on_update_virtual_size(_virtrct)
      # HINT: override it for custom actions...
    end

    # @!endgroup

    def inspect
      "#<Wx::SF::ShapeCanvas:#{object_id}>"
    end

    private

    # Validate selection so the shapes in the given list can be processed by the clipboard functions
    # @param [Array<Wx::SF::Shape>] selection
    # @param [Boolean] storeprevpos
    def validate_selection_for_clipboard(selection, storeprevpos)
      selection.dup.each do |shape|
        if shape.get_parent_shape
           # remove child shapes without parent in the selection and without STYLE::PARENT_CHANGE style
           # defined from the selection
          if !shape.has_style?(Shape::STYLE::PARENT_CHANGE) && !selection.include?(shape.get_parent_shape)
            selection.delete(shape)
          else
            # convert relative position to absolute position if the shape is copied
            # without its parent
            unless selection.include?(shape.get_parent_shape)
              store_prev_position(shape) if storeprevpos
              shape.set_relative_position(shape.get_absolute_position)
            end
          end
        end
    
        append_assigned_connections(shape, selection, false)
      end
    end

    #  Append connections assigned to shapes in given list to this list as well
    # @param [Wx::SF::Shape] shape
    # @param [Array<Wx::SF::Shape>] selection
    # @param [Boolean] childrenonly
    def append_assigned_connections(shape, selection, childrenonly)
      # add connections assigned to copied topmost shapes and their children to the copy list
      lst_children = shape.get_child_shapes(ANY, RECURSIVE)
    
      # get connections assigned to the parent shape
      lst_connections = @diagram.get_assigned_connections(shape, LineShape, Shape::CONNECTMODE::BOTH) unless childrenonly
      lst_connections ||= []
      # get connections assigned to its child shape
      lst_children.each do |child|
        # get connections assigned to the child shape
        @diagram.get_assigned_connections(child, LineShape, Shape::CONNECTMODE::BOTH, lst_connections)
      end
    
      # insert connections to the copy list
      lst_connections.each do |line|
        selection << line unless selection.include?(line)
      end
    end

    #  Remove given shape for temporary containers
    # @param [Wx::SF::Shape] shape
    def remove_from_temporaries(shape)
      if shape
        @current_shapes.delete(shape)
        @new_line_shape = nil if @new_line_shape == shape
        @unselected_shape_under_cursor = nil if @unselected_shape_under_cursor == shape
        @selected_shape_under_cursor = nil if @selected_shape_under_cursor == shape
        @topmost_shape_under_cursor = nil if @topmost_shape_under_cursor == shape
      end
    end

    #  Clear all temporary containers 
    def clear_temporaries
      @current_shapes.clear
      @new_line_shape = nil
      @unselected_shape_under_cursor = nil
      @selected_shape_under_cursor = nil
      @topmost_shape_under_cursor = nil
    end

    #  Assign give shape to parent at given location (if exists)
    # @param [Wx::SF::Shape] shape
    # @param [Wx::Point] parentpos
    def reparent_dropped_shape(shape, parentpos)
      return unless @diagram

      # set new parent if possible
      if shape.has_style?(Shape::STYLE::PARENT_CHANGE) && !shape.is_a?(LineShape)
        # is shape dropped into accepting shape?

        # get all shapes at drop position in reversed z-order
        shapes_at_pos = get_shapes_at_position(parentpos).reverse
        # see if we can find a non-LineShape drop target
        parent_shape = shapes_at_pos.find do |s|
          # consider non-LineShapes that are unselected and not the dropped shape itself or one of it's (grand-)children
          !s.is_a?(Wx::SF::LineShape) && !s.selected? && shape != s && !shape.include_child_shape?(s)
        end
        # if none found consider line shapes
        parent_shape = shapes_at_pos.find do |s|
          # consider LineShapes that are unselected and not the dropped shape itself or one of it's (grand-)children
          s.is_a?(Wx::SF::LineShape) && !s.selected? && shape != s && !shape.include_child_shape?(s)
        end unless parent_shape
        # In case the matching shape does not accept the dropped child and has style PROPAGATE_DROPPING
        # see if this shape has a parent that does also matches the position and DOES accept the child.
        # This allows dropping shapes onto child shapes inside a (container) shapes like
        # grids and/or boxes.
        while parent_shape && !parent_shape.is_child_accepted(shape.class)
          parent_shape = parent_shape.has_style?(Shape::STYLE::PROPAGATE_DROPPING) ? parent_shape.parent_shape : nil
          parent_shape = nil if parent_shape && !parent_shape.get_bounding_box.contains?(parentpos)
        end
        # parent_shape = nil if parent_shape && !parent_shape.is_child_accepted(shape.class)

        prev_parent = shape.get_parent_shape

        if parent_shape
          # in rare cases (where childs are expanded to fill a parent and have PROPAGATE_SELECTION)
          # the matched drop parent may actually a child of the shape being dropped
          # guard against that (since that would lead to illegal circular references)
          if parent_shape != shape && !shape.include_child_shape?(parent_shape, true)
            # update relative position to new parent
            apos = shape.get_absolute_position - parent_shape.get_absolute_position
            shape.set_relative_position(apos)
            # reparent
            @diagram.reparent_shape(shape, parent_shape)
            # notify the parent shape about dropped child
            parent_shape.on_child_dropped(apos, shape)
          end
        else
          if @diagram.is_top_shape_accepted(shape.class)
            # move relative to previous parent
            shape.move_by(prev_parent.get_absolute_position) if prev_parent
            # reparent
            @diagram.reparent_shape(shape, parent_shape)
          end
        end
    
        prev_parent.update if prev_parent
        parent_shape.update if parent_shape && parent_shape != prev_parent
      end
    end

    #  Store previous shape's position modified in validate_selection_for_clipboard() function
    # @param [Wx::SF::Shape] shape
    def store_prev_position(shape)
      @prev_positions[shape] = shape.get_relative_position.dup
    end

    #  Restore previously stored shape positions and clear the storage
    def restore_prev_positions
      @prev_positions.each_pair { |shape, pos| shape.set_relative_position(pos) }
      @prev_positions.clear
    end

    # private event handlers

	  # Event handler called when the canvas should be repainted.
	  # @param [Wx::PaintEvent] _event Paint event
    def _on_paint(_event)
      paint_buffered do |paint_dc|
        if ShapeCanvas.gc_enabled?
          Wx::GCDC.draw_on(paint_dc) do |gdc|
            prepare_dc(gdc)

            # scale  GC
            gc = gdc.get_graphics_context
            gc.scale(@settings.scale, @settings.scale)

            draw_background(gdc, FROM_PAINT)
            draw_content(gdc, FROM_PAINT)
            draw_foreground(gdc, FROM_PAINT)
          end
        else
          Wx::ScaledDC.draw_on(paint_dc, @settings.scale) do |dc|
            prepare_dc(dc)
            draw_background(dc, FROM_PAINT)
            draw_content(dc, FROM_PAINT)
            draw_foreground(dc, FROM_PAINT)
          end
        end
      end
    end

	  # Event handler called when the canvas should be erased.
	  # @param [Wx::EraseEvent] _event Erase event
    def _on_erase_background(_event)
      # do nothing to suppress window flickering
    end

	  # Event handler called when the mouse pointer leaves the canvas window.
	  # @param [Wx::MouseEvent] event Mouse event
    def _on_leave_window(event)
      case @working_mode
      when MODE::MULTISELECTION
      when MODE::SHAPEMOVE
      when MODE::CREATECONNECTION
      when MODE::HANDLEMOVE
      when MODE::MULTIHANDLEMOVE
      else
        @working_mode = MODE::READY
      end
    
      event.skip
    end

	  # Event handler called when the mouse pointer enters the canvas window.
	  # @param [Wx::MouseEvent] event Mouse event
    def _on_enter_window(event)
      @prev_mouse_pos = event.get_position
    
      lpos = dp2lp(event.get_position)
    
      case @working_mode
      when MODE::MULTISELECTION
        unless event.left_is_down
          update_multiedit_size
          @shp_multi_edit.show(false)
          @working_mode = MODE::READY
    
          invalidate_visible_rect
        end

      when MODE::HANDLEMOVE
        unless event.left_is_down
          if @selected_handle
            if @selected_handle.get_parent_shape.is_a?(LineShape)
              @selected_handle.get_parent_shape.send(:set_line_mode, LineShape::LINEMODE::READY)
            end
    
            @selected_handle.send(:_on_end_drag, lpos)
    
            save_canvas_state
            @working_mode = MODE::READY
            @selected_handle = nil
    
            invalidate_visible_rect
          end
        end

      when MODE::MULTIHANDLEMOVE
        unless event.left_is_down
          if @selected_handle
            @selected_handle.send(:_on_end_drag, lpos)
    
            save_canvas_state
            @working_mode = MODE::READY
    
            invalidate_visible_rect
          end
        end

      when MODE::SHAPEMOVE
        unless event.left_is_down
          lst_selection = get_selected_shapes
    
          move_shapes_from_negatives
          update_virtual_size
    
          if lst_selection.size > 1
            update_multiedit_size
            @shp_multi_edit.show(true)
            @shp_multi_edit.show_handles(true)
          end
    
          lst_selection.each { |shape|  shape.send(:_on_end_drag, lpos) }

          @working_mode = MODE::READY
    
          invalidate_visible_rect
        end
      end
    
      refresh_invalidated_rect
    
      event.skip
    end

	  # Event handler called when the canvas size has changed.
	  # @param [Wx::SizeEvent] event Size event
    def _on_resize(event)
      refresh(false) if has_style?(STYLE::GRADIENT_BACKGROUND)

      event.skip
    end
    
    # original private event handlers
    
	  # Original private event handler called when the canvas is clicked by
	  # left mouse button. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
	  # @param [Wx::MouseEvent] event Mouse event
	  # @see Wx::SF::ShapeCanvas#on_left_down
    def _on_left_down(event)
      on_left_down(event)

      event.skip
    end

	  # Original private event handler called when the canvas is double-clicked by
	  # left mouse button. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
	  # @see Wx::SF::ShapeCanvas#on_left_double_click
    def _on_left_double_click(event)
      on_left_double_click(event)

      event.skip
    end

	  # Original private event handler called when the left mouse button
	  # is release above the canvas. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_left_up
    def _on_left_up(event)
      on_left_up(event)

      event.skip
    end

	  # Original private event handler called when the canvas is clicked by
	  # right mouse button. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_right_down
    def _on_right_down(event)
      on_right_down(event)

      event.skip
    end

	  # Original private event handler called when the canvas is double-clicked by
	  # right mouse button. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_right_double_click
    def _on_right_double_click(event)
      on_right_double_click(event)

      event.skip
    end

	  # Original private event handler called when the right mouse button
	  # is release above the canvas. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_right_up
    def _on_right_up(event)
      on_right_up(event)

      event.skip
    end

	  # Original private event handler called when the mouse pointer is moving above
	  # the canvas. The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_mouse_move
    def _on_mouse_move(event)
      lpos = dp2lp(event.get_position)

      update_shape_under_cursor_cache(lpos)

      # call user event handler
      on_mouse_move(event)

      event.skip
    end

	  # Original private event handler called when the mouse wheel position is changed.
	  # The handler calls user-overridable event handler function and skips the event
	  # for next possible processing.
    # @param [Wx::MouseEvent] event Mouse event
    # @see Wx::SF::ShapeCanvas#on_mouse_wheel
    def _on_mouse_wheel(event)
      on_mouse_wheel(event) if has_style?(STYLE::PROCESS_MOUSEWHEEL)

      event.skip
    end

	  # Original private event handler called when any key is pressed.
	  # The handler calls user-overridable event handler function
	  # and skips the event for next possible processing.
	  # @param [Wx::KeyEvent] event Keyboard event
	  # @see Wx::SF::ShapeCanvas#on_key_down
    def _on_key_down(event)
      on_key_down(event)

      event.skip
    end

    if Wx.has_feature?(:USE_DRAG_AND_DROP)

	  # Function is called by associated wxSFCanvasDropTarget after any dragged shapes
	  # are dropped to the canvas.
	  # @param [Integer] x X-coordinate of a position the data was dropped to
	  # @param [Integer] y Y-coordinate of a position the data was dropped to
	  # @param [Wx::DragResult] deflt Drag result
	  # @param [Wx::ShapeDataObject] data a data object encapsulating dropped data
	  # @see Wx::SF::CanvasDropTarget
    def _on_drop(x, y, deflt, data)
      if data && Wx::SF::ShapeDataObject === data
        lst_new_content = FIRM.deserialize(data.get_data_here)
        if lst_new_content && !lst_new_content.empty?
          lst_parents_to_update = []
          lpos = dp2lp(Wx::Point.new(x, y))

          dx = 0
          dy = 0
          if @dnd_started_here
            dx = lpos.x - @dnd_started_at.x
            dy = lpos.y - @dnd_started_at.y
          end

          parent = @diagram.get_shape_at_position(lpos, 1, SEARCHMODE::UNSELECTED)
          # In case the located shape does not accept ANY children and has style PROPAGATE_DROPPING
          # see if this shape has a parent that does also match the position and DOES accept children.
          # This allows dropping shapes onto child shapes inside a (container) shapes like
          # grids and/or boxes.
          while parent&.does_not_accept_children?
            parent = parent.has_style?(Shape::STYLE::PROPAGATE_DROPPING) ? parent.parent_shape : nil
            parent = nil if parent && !parent.get_bounding_box.contains?(lpos)
          end

          # add each shape to diagram keeping only those that are accepted
          lst_new_content.select! do |shape|
            shape.move_by(dx, dy)
            # do not reparent connection lines
            rc = if (shape.is_a?(LineShape) && !shape.stand_alone?) || parent.nil?
                   @diagram.add_shape(shape,
                                      nil,
                                      lp2dp(shape.get_absolute_position.to_point),
                                      INITIALIZE,
                                      DONT_SAVE_STATE)
                 else
                   @diagram.add_shape(shape,
                                      parent,
                                      lp2dp((shape.get_absolute_position - parent.get_absolute_position).to_point),
                                      INITIALIZE,
                                      DONT_SAVE_STATE)
                 end
            rc == ERRCODE::OK # keep or remove?
          end

          # verify newly added shapes (may remove shapes from list)
          @diagram.send(:on_import, lst_new_content)

          update_virtual_size # update for new shapes

          # notify parents and collect for update
          lst_new_content.each do |shape|
            if (parent_shape = shape.get_parent_shape)
              parent_shape.on_child_dropped(shape.get_absolute_position - parent_shape.get_absolute_position,
                                            shape)
              lst_parents_to_update << parent_shape unless lst_parents_to_update.include?(parent_shape)
            end
          end

          deselect_all

          lst_parents_to_update.each { |shape| shape.update }

          unless @dnd_started_here
            save_canvas_state
            refresh(false)
          end

          # call user-defined drop handler
          on_drop(x, y, deflt, lst_new_content)
        end
      end
    end
      
    end

    def _notify_canvas_change(change, *args)
      @diagram.get_all_shapes.each { |shape| shape.send(:_on_canvas, change, *args) } if @diagram
    end

    def _query_canvas_change(change, *args)
      return true unless @diagram
      @diagram.get_all_shapes.all? { |shape| shape.send(:_on_canvas, change, *args) }
    end

  end # class ShapeCanvas

end

# module Wx::SF
