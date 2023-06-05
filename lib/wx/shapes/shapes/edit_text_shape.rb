# Wx::SF::EditTextShape - edit text shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/text_shape'

module Wx::SF

  CANCEL_TEXT_CHANGES = false
  APPLY_TEXT_CHANGES = true

  class ContentCtrl < Wx::TextCtrl

    # Constructor.
    # @param [Wx::Window] parent Pointer to the parent window
    # @param [Integer] id ID of the text control window
    # @param [Wx::SF::EditTextShape] parent_shape Pointer to the parent editable text shape
    # @param [String] content Initial content of the text control
    # @param [Wx::Point] pos Initial position
    # @param [Wx::Size] size Initial size
    # @param [Integer] style Window style
    def initialize(parent, id, parent_shape, content, pos, size, style)
      super(parent, id, content, pos, size, Wx::TE_PROCESS_ENTER | Wx::TE_PROCESS_TAB | Wx::NO_BORDER | style)
      @parent = parent
      @parent_shape = parent_shape
      @prev_content = content

      set_insertion_point_end
      if @parent_shape
        # update the font size in accordance to the canvas scale
        font = @parent_shape.get_font
        font.set_point_size((font.get_point_size * @parent_shape.get_parent_canvas.get_scale).to_i)

        set_font(font)
        set_background_colour(Wx::Colour.new(200, 200, 200))
        set_focus
      end
    end

    # Finish the editing process/
	  # @param [Boolean] apply If true then changes made in edited text will be applied on text shape, otherwise it will be canceled
    def quit(apply = APPLY_TEXT_CHANGES)
      self.hide

      if @parent_shape
        @parent_shape.send(:text_ctrl, nil)
        @parent_shape.set_style(@parent_shape.send(:current_state))

        # save canvas state if the textctrl content has changed...
        if apply && @prev_content != get_value
          @parent_shape.set_text(get_value)
          @prev_content = get_value

          # inform parent shape canvas about text change...
          @parent_shape.get_parent_canvas.on_text_change(@parent_shape)
          @parent_shape.get_parent_canvas.save_canvas_state
        end

        @parent_shape.update
        @parent_shape.get_parent_canvas.refresh
      end

      self.destroy
    end

    protected

	  # Event handler called if the text control lost the focus.
    # @param [Wx::FocusEvent] _event Reference to the event class instance
    def on_kill_focus(_event)
      # noop
    end

	  # Event handler called if the key was pressed in the text control.
	  # @param [Wx::KeyEvent] event Reference to the event class instance
    def on_key_down(event)
      case event.get_key_code
      when Wx::K_ESCAPE
        quit(CANCEL_TEXT_CHANGES)
      when Wx::K_TAB
        quit(APPLY_TEXT_CHANGES)
      when Wx::K_RETURN
        # enter new line if SHIFT key was pressed together with the ENTER key
        if Wx::get_key_state(Wx::K_SHIFT)
          event.skip
        else
          quit(APPLY_TEXT_CHANGES)
        end
      else
        event.skip
      end
    end
    
  end

  class EditTextShape < TextShape

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, diagram)
    #   User constructor.
    #   @param [Wx::Point] pos Initial position
    #   @param [Wx::Size] size Initial size
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)

    end

  end

end
