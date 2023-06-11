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

      evt_kill_focus :on_kill_focus
      evt_key_down :on_key_down

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
        @parent_shape.send(:set_text_ctrl, nil)
        @parent_shape.set_style(@parent_shape.send(:get_current_state))

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

  # Auxiliary class providing necessary functionality needed for dialog-based
  # modification of a content of the text shape.
  # @see EditTextShape
  class DetachedContentCtrl < Wx::Dialog

	  # Constructor.
    # @param [Wx::Window] parent Pointer to the parent window
    # @param [Integer] id ID of the text control window
    # @param [String] title Dialog's title
    # @param [Wx::Point] pos Initial position
    # @param [Wx::Size] size Initial size
    # @param [Integer] style Window style
    def initialize(parent, id = Wx::ID_ANY, title = 'Edit content',
                   pos = Wx::DEFAULT_POSITION, size = Wx::DEFAULT_SIZE,
                   style = Wx::DEFAULT_DIALOG_STYLE|Wx::RESIZE_BORDER)
      set_size_hints(Wx::Size.new(-1,-1), Wx::DEFAULT_SIZE)

      main_sizer = Wx::VBoxSizer.new

      @text = Wx::TextCtrl.new(self, Wx::ID_ANY, '', Wx::DEFAULT_POSITION, [350,100], Wx::TE_MULTILINE)
      @text.set_min_size([350,100])

      main_sizer.add(@text, 1, Wx::ALL|Wx::EXPAND, 5)

      button_sizer = Wx::StdDialogButtonSizer.new
      button_sizer_ok = Wx::Button.new(self, Wx::ID_OK)
      button_sizer.add_button(button_sizer_ok)
      button_sizer_cancel = Wx::Button.new(self, Wx::ID_CANCEL)
      button_sizer.add_button(button_sizer_cancel)
      button_sizer.realize
      main_sizer.add(button_sizer, 0, Wx::ALIGN_RIGHT|Wx::BOTTOM|Wx::RIGHT, 5)

      set_sizer(main_sizer)
      layout
      main_sizer.fit(self)

      centre(Wx::BOTH)
    end
	
	  # Set content of dialog's text edit control.
	  # @param [String] txt Text content
    def set_content(txt)
      @text.set_value(txt)
    end

	  # Get content of dialog's text edit control.
	  # @return [String] Edited text
    def get_content
      @text.get_value
    end

  end

  # Class encapsulating the editable text shape. It extends the basic text shape.
  # @see Wx::SF::TextShape
  class EditTextShape < TextShape

    class EDITTYPE < Wx::Enum
      INPLACE = self.new(0)
      DIALOG = self.new(1)
      DISABLED = self.new(1)
    end

    # Default values
    module DEFAULT
      # Default value of EditTextShape @force_multiline data member
      FORCE_MULTILINE = false
      # Default value of EditTextShape @edit_type data member
      EDIT_TYPE = EDITTYPE::INPLACE
    end

    property :force_multiline, :edit_type

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, txt, diagram)
    #   User constructor.
    #   @param [Wx::Point] pos Initial position
    #   @param [String] txt Initial content
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)
      super
      @text_ctrl = nil
      @force_multiline = DEFAULT::FORCE_MULTILINE
      @edit_type = DEFAULT::EDIT_TYPE
      @current_state = 0
    end

    attr_reader :force_multiline

	  # Set way how the text shape's content can be edited.
	  # @param [EDITTYPE] type Edit control type
	  # @see EDITTYPE
    def set_edit_type(type)
      @edit_type = type
    end
    alias :edit_type= :set_edit_type

	  # Get current type of text shape's edit control.
	  # @return [EDITTYPE] Type of edit control
	  # @see EDITTYPE
    def get_edit_type
      @edit_type
    end
    alias :edit_type :get_edit_type

	  # Get assigned text control allowing user to change the
    # shape's content directly in the canvas.
	  # @return [ContentCtrl] instance of wxSFContentCtrl class
    def get_text_ctrl
      @text_ctrl
    end
    alias :text_ctrl :get_text_ctrl

    def set_text_ctrl(txt_ctrl)
      @text_ctrl = txt_ctrl
    end
    private :set_text_ctrl

	  # Switch the shape to a label editing mode.
    def edit_label
      if get_parent_canvas
        shp_pos = get_absolute_position
        scale = get_parent_canvas.get_scale
        dx, dy = get_parent_canvas.calc_unscrolled_position(0, 0)
        
        case @edit_type
        when EDITTYPE::INPLACE
          shp_bb = get_bounding_box
          style = 0
          style = Wx::TE_MULTILINE if @force_multiline || @text.index("\n")

          # set minimal control size
          shp_bb.set_width(50) if @text == '' || (style == Wx::TE_MULTILINE && shp_bb.width < 50)

          @current_state = get_style
          remove_style(STYLE::SIZE_CHANGE)

          @text_ctrl = ContentCtrl.new(get_parent_canvas, Wx::ID_ANY, self, @text,
                                       [((shp_pos.x * scale) - dx).to_i, ((shp_pos.y * scale) - dy).to_i],
                                       [(shp_bb.width * scale).to_i, (shp_bb.height * scale).to_i], style)

        when EDITTYPE::DIALOG
          prev_text = get_text

          DetachedContentCtrl(get_parent_canvas) do |text_dlg|
            text_dlg.set_content(prev_text)

            if text_dlg.show_modal == Wx::ID_OK
              if text_dlg.get_content != prev_text
                set_text(text_dlg.get_content)

                get_parent_canvas.on_text_change(self)
                get_parent_canvas.save_canvas_state

                update
                get_parent_canvas.refresh(false)
              end
            end
          end
        end
      end
    end

	  # Force the edit text control to be multiline
    # @param [Boolean] multiline If true then the associated text control will be always multiline
    def set_force_multiline(multiline)
      @force_multiline = multiline
    end
    alias :force_multiline= :set_force_multiline

	  # Event handler called when the shape was double-clicked.
    # The function can be overridden if necessary.
	  # @param [Wx::Point] pos Mouse position.
    def on_left_double_click(pos)
      # HINT: override it if necessary...
      edit_label
    end

	  # Event handler called when any key is pressed (in the shape canvas).
    # The function can be overridden if necessary.
    #
    # The function is called by the framework (by the shape canvas).
	  # @param [Integer] key The key code
	  # @return [Boolean] The function must return true if the default event routine should be called
    # as well, otherwise false
	  # @see Shape#on_key
    def on_key(key)
      # HINT: override it if necessary...
      if key == Wx::K_F2
        edit_label if active? && visible?
      end
      super
    end

    protected

    # Event handler called by ShapeCanvas to request,report canvas changes.
    # @param [ShapeCanvas::CHANGE] change change type indicator
    # @param [Array] _args any additional arguments
    # @return [Boolean,nil]
    def _on_canvas(change, *_args)
      if change == ShapeCanvas::CHANGE::FOCUS
        text_ctrl = get_text_ctrl
        text_ctrl.quit(APPLY_TEXT_CHANGES) if text_ctrl
      end
      super
    end

    private

    # Return cached state
    # @return [Integer]
    def get_current_state
      @current_state
    end

  end

end
