# Wx::SF::Printout - printout class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  class Printout < Wx::PRT::Printout

    # Constructor.
    # @param [String] title
    # @param [ShapeCanvas] canvas canvas to print
    def initialize(title, canvas)
      super(title)
      @canvas = canvas
    end

    # Access (set/get) canvas (to be) printed.
    attr_accessor :canvas

    # Called by printing framework. Functions TRUE if a page of given index already exists in printed document.
    # This function can be overridden if necessary.
    def has_page(page)
      page == 1
    end

    # Called by printing framework. Initialize print job. This function can be overridden if necessary. 
    def on_begin_document(start_page, end_page)
      # HINT: perform custom actions...
      super
    end

    # Called by printing framework. Deinitialize the print job. This function can be overridden if necessary. 
    def on_end_document
      # HINT: perform custom actions...
      super
    end

    # Called by printing framework. It does the print job. This function can be overridden if necessary. 
    def on_print_page(page)
      dc = get_dc
      if dc && @canvas
        # get drawing size
        total_bb = @canvas.get_total_bounding_box
        max_x = total_bb.right
        max_y = total_bb.bottom
  
        # set printing mode
        case @canvas.get_print_mode
        when ShapeCanvas::PRINTMODE::FIT_TO_PAGE
          fit_this_size_to_page([max_x, max_y])
          fit_rect = get_logical_page_rect

        when ShapeCanvas::PRINTMODE::FIT_TO_PAPER
          fit_this_size_to_paper([max_x, max_y])
          fit_rect = get_logical_paper_rect

        when ShapeCanvas::PRINTMODE::FIT_TO_MARGINS
          fit_this_size_to_page_margins([max_x, max_y], ShapeCanvas.page_setup_data)
          fit_rect = get_logical_page_margins_rect(ShapeCanvas.page_setup_data)

        when ShapeCanvas::PRINTMODE::MAP_TO_PAGE
          map_screen_size_to_page
          fit_rect = get_logical_page_rect

        when ShapeCanvas::PRINTMODE::MAP_TO_PAPER
          map_screen_size_to_paper
          fit_rect = get_logical_paper_rect

        when ShapeCanvas::PRINTMODE::MAP_TO_MARGINS
          map_screen_size_to_page
          fit_rect = get_logical_page_margins_rect(ShapeCanvas.page_setup_data)

        when ShapeCanvas::PRINTMODE::MAP_TO_DEVICE
          map_screen_size_to_device
          fit_rect = get_logical_page_rect

        else
          fit_rect = Wx::Rect.new
        end

        # This offsets the image so that it is centered within the reference
        # rectangle defined above.
        xoff = ((fit_rect.width - max_x - total_bb.left) / 2) - fit_rect.x
        yoff = ((fit_rect.height - max_y - total_bb.top) / 2) - fit_rect.y
  
        case @canvas.get_print_h_align
        when ShapeCanvas::HALIGN::LEFT
          xoff = 0
        when ShapeCanvas::HALIGN::RIGHT
          xoff = fit_rect.width - total_bb.width
        end
  
        case @canvas.get_print_v_align
        when ShapeCanvas::VALIGN::TOP
          yoff = 0
        when ShapeCanvas::VALIGN::BOTTOM
          yoff = fit_rect.height - total_bb.height
        end
  
        offset_logical_origin(xoff, yoff)
  
        # store current canvas properties
        prev_scale = @canvas.get_scale

        # draw the canvas content without any scale (dc is scaled by the printing framework)
        @canvas.set_scale(1.0)
        @canvas.draw_background(dc, NOT_FROM_PAINT) if @canvas.has_style?(ShapeCanvas::STYLE::PRINT_BACKGROUND)
        @canvas.draw_content(dc, NOT_FROM_PAINT)
        @canvas.draw_foreground(dc, NOT_FROM_PAINT)
        @canvas.set_scale(prev_scale)
  
        return true
      end
      false
    end

    # Called by printing framework. Supply information about printed pages. This function can be overridden if necessary. 
    def get_page_info
      [1,1,1,1]
    end

  end

end
