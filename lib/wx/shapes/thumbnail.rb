# Wx::SF::Thumbnail - canvas thumbnail class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  class Thumbnail < Wx::Panel

    # Internally used IDs
    module ID
		  ID_UPDATETIMER = Wx::ID_HIGHEST + 1
		  IDM_SHOWELEMENTS = ID_UPDATETIMER+1
		  IDM_SHOWCONNECTIONS = ID_UPDATETIMER+2
    end

    # Thumbnail style 
    class THUMBSTYLE < Wx::Enum
		  # Show diagram elements (excluding connections) in the thumbnail.
		  SHOW_ELEMENTS = self.new(1)
		  # Show diagram connections in the thumbnail.
		  SHOW_CONNECTIONS = self.new(2)
    end

    def initialize(parent)
      super(parent, Wx::ID_ANY, size: [200, 150], style: Wx::TAB_TRAVERSAL | Wx::FULL_REPAINT_ON_RESIZE)
      set_extra_style(Wx::WS_EX_BLOCK_EVENTS)
      set_size_hints([10, 10])

      @canvas = nil
      @scale = 1.0
      @thumb_style = THUMBSTYLE::SHOW_ELEMENTS | THUMBSTYLE::SHOW_CONNECTIONS
      @prev_mouse_pos = nil

      @update_timer = Wx::Timer.new(self, ID_UPDATETIMER)

      evt_paint :_on_paint
      evt_erase_background :_on_erase_background
      evt_motion :_on_mouse_move
      evt_left_down :_on_left_down
      evt_right_down :_on_right_down
      evt_timer(ID_UPDATETIMER, :_on_timer)
      evt_update_ui(IDM_SHOWELEMENTS, :_on_update_show_elements)
      evt_update_ui(IDM_SHOWCONNECTIONS, :_on_update_show_connections)
      evt_menu(IDM_SHOWELEMENTS, :_on_show_elements)
      evt_menu(IDM_SHOWCONNECTIONS, :_on_show_connections)
    end

    # Access (get/set) thumbnail style.
    attr_accessor :thumb_style

	  # Set canvas managed by the thumbnail.
	  # @param [ShapeCanvas] canvas shape canvas
    def set_canvas(canvas)
      @canvas = canvas

      if @canvas
        @update_timer.start(100)
      else
        @update_timer.stop
        refresh(false)
      end
    end
	
	  # Implementation of drawing of the thumbnail's content. This virtual function can be overridden
    # by the user for customization of the thumbnail appearance.
	  # @param [Wx::DC] dc Reference to output device context
    def draw_content(dc)
      # HINT: overload it for custom actions...
      bmp_pen = nil
      @canvas.get_diagram.get_all_shapes.each do |shape|
        if (@thumb_style & THUMBSTYLE::SHOW_CONNECTIONS) != 0 && shape.is_a?(LineShape)
          shape.draw(dc, WITHOUTCHILDREN)
        elsif (@thumb_style & THUMBSTYLE::SHOW_ELEMENTS) != 0
          if shape.is_a?(BitmapShape)
            bmp_pen ||= Wx::Pen.new(Wx::BLACK, 1, Wx::PENSTYLE_DOT)
            dc.with_pen(bmp_pen) do
              dc.with_brush(Wx::WHITE_BRUSH) do
                dc.draw_rectangle(shape.get_bounding_box)
              end
            end
          elsif !shape.is_a?(LineShape)
            shape.draw(dc, WITHOUTCHILDREN)
          end
        end
      end
    end

    protected

    # Internally used event handler.
    # @param [Wx::PaintEvent] _event
    def _on_paint(_event)
      paint_buffered do |dc|
        # clear background
        dc.set_background(Wx::Brush.new(Wx::Colour.new(150, 150, 150)))
        dc.clear
        
        if @canvas
          sz_canvas = @canvas.get_client_size
          sz_virt_canvas = @canvas.get_virtual_size
          sz_canvas_offset = get_canvas_offset
          sz_thumb = get_client_size
          
          # scale and copy bitmap to DC
          cx = sz_virt_canvas.x
          cy = sz_virt_canvas.y
          tx = sz_thumb.x
          ty = sz_thumb.y
          
          if (tx/ty) > (cx/cy)
            @scale = ty.to_f/cy
          else
            @scale = tx.to_f/cx
          end
      
          # draw virtual canvas area
          dc.with_pen(Wx::WHITE_PEN) do
            dc.with_brush(Wx::Brush.new(Wx::Colour.new(240, 240, 240))) do
              dc.draw_rectangle(0, 0, (sz_virt_canvas.x*@scale).to_i, (sz_virt_canvas.y*@scale).to_i)

              # draw top level shapes
              Wx::ScaledDC.draw_on(dc, @scale * @canvas.get_scale)  do |sdc|
                draw_content(sdc)
              end

              # draw canvas client area
              dc.set_pen(Wx::RED_PEN)
              dc.set_brush(Wx::TRANSPARENT_BRUSH)
              dc.draw_rectangle((sz_canvas_offset.x*@scale).to_i, (sz_canvas_offset.y*@scale).to_i, (sz_canvas.x*@scale).to_i, (sz_canvas.y*@scale).to_i)
            end
          end
        end
        
        dc.set_background(Wx::NULL_BRUSH)
      end
    end

    # Get offset (view start) of managed shape canvas defined in pixels.
    # @return [Wx::Size] Canvas offset in pixels
    def get_canvas_offset
      if @canvas
        ux, uy = @canvas.get_scroll_pixels_per_unit
        offset_x, offset_y = @canvas.get_view_start

        return Wx::Size.new(offset_x*ux, offset_y*uy)
      end
      Wx::Size.new
    end

    private

    # Internally used event handler.
    # @param [Wx::EraseEvent] _event
    def _on_erase_background(_event)
      # noop
    end

    # Internally used event handler.
    # @param [Wx::MouseEvent] event
    def _on_mouse_move(event)
      if @canvas && is_shown && event.dragging
        ux, uy = @canvas.get_scroll_pixels_per_unit
        
        sz_delta = @prev_mouse_pos ? event.get_position - @prev_mouse_pos : event.get_position
        sz_canvas_offset = get_canvas_offset
        
        @canvas.scroll(((sz_delta.x/@scale + sz_canvas_offset.x)/ux).to_i, ((sz_delta.y/@scale + sz_canvas_offset.y)/uy).to_i)
        
        @prev_mouse_pos = event.get_position
        
        refresh(false)
      end
    end

    # Internally used event handler.
    # @param [Wx::MouseEvent] event
    def _on_left_down(event)
      @prev_mouse_pos = event.get_position
    end

    # Internally used event handler.
    # @param [Wx::MouseEvent] event
    def _on_right_down(event)
      menu_popup = Wx::Menu.new

      menu_popup.append_check_item(IDM_SHOWELEMENTS, 'Show elements')
      menu_popup.append_check_item(IDM_SHOWCONNECTIONS, 'Show connections')

      popup_menu(menu_popup, event.get_position)
    end

    # Internally used event handler.
    # @param [Wx::TimerEvent] _event
    def _on_timer(_event)
      refresh(false) if @canvas && is_shown
    end

    # Internally used event handler.
    # @param [Wx::CommandEvent] _event
    def _on_show_elements(_event)
      if (@thumb_style & THUMBSTYLE::SHOW_ELEMENTS) != 0
        @thumb_style &= ~THUMBSTYLE::SHOW_ELEMENTS
      else
        @thumb_style |= THUMBSTYLE::SHOW_ELEMENTS
      end
    end

    # Internally used event handler.
    # @param [Wx::CommandEvent] _event
    def _on_show_connections(_event)
      if (@thumb_style & THUMBSTYLE::SHOW_CONNECTIONS) != 0
        @thumb_style &= ~THUMBSTYLE::SHOW_CONNECTIONS
      else
        @thumb_style |= THUMBSTYLE::SHOW_CONNECTIONS
      end
    end

    # Internally used event handler.
    # @param [Wx::UpdateUIEvent] event
    def _on_update_show_elements(event)
      event.check((@thumb_style & THUMBSTYLE::SHOW_ELEMENTS) != 0)
    end

    # Internally used event handler.
    # @param [Wx::UpdateUIEvent] event
    def _on_update_show_connections(event)
      event.check((@thumb_style & THUMBSTYLE::SHOW_CONNECTIONS) != 0)
    end

  end

end
