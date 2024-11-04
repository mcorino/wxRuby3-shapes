# Wx::SF - Demo Dialogs
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes'

module Dialogs

  class << self
    def get_enum_choices(enum, excludes: nil)
      enumerators = enum.enumerators(excludes).sort_by(&:first)
      enumerators.collect { |_, esym| esym.to_s }
    end

    def get_enum_index(enumerator, excludes: nil)
      enum = enumerator.class
      enumerators = enum.enumerators(excludes).sort_by(&:first)
      enumerators.index { |e, _| enumerator == e }
    end

    def index_to_enum(enum, index, excludes: nil)
      enumerators = enum.enumerators(excludes).sort_by(&:first)
      enum[enumerators[index].last]
    end

    def selections_to_enum(enum, selections, excludes: nil)
      enumerators = enum.enumerators(excludes).sort_by(&:first)
      selections.inject(enum.new(0)) do |mask, ix|
        mask | enumerators[ix].first
      end
    end

    def enum_to_selections(enum, style, excludes: nil)
      sel = []
      enumerators = enum.enumerators(excludes).sort_by(&:first)
      enumerators.each_with_index do |(e, _), ix|
        sel << ix if style.allbits?(e)
      end
      sel
    end
  end

  class WXSFPreferencesDialog < Wx::PropertySheetDialog

    # @param [Wx::Window] parent
    # @param [FrameCanvas] canvas
    def initialize(parent, canvas)
      super()

      create(parent, Wx::ID_ANY, "Preferences")
      create_buttons(Wx::OK|Wx::CANCEL|Wx::APPLY)

      @canvas = canvas
      @changed = false

      book_ctrl.add_page(canvas_panel, 'Appearance', true)
      book_ctrl.add_page(behaviour_panel, 'Behaviour', true)
      book_ctrl.add_page(print_panel, 'Print', true)
      book_ctrl.add_page(shapes_panel, 'Shapes', true)

      book_ctrl.change_selection(0)

      layout_dialog

      evt_update_ui Wx::ID_ANY, :on_update_ui
      evt_radiobutton Wx::ID_ANY, :on_change
      evt_checkbox Wx::ID_ANY, :on_change
      evt_colourpicker_changed Wx::ID_ANY, :on_change
      evt_fontpicker_changed Wx::ID_ANY, :on_change
      evt_combobox Wx::ID_ANY, :on_change
      evt_spinctrl Wx::ID_ANY, :on_change
      evt_spinctrldouble Wx::ID_ANY, :on_change
      evt_button Wx::ID_APPLY, :on_apply
      evt_button Wx::ID_OK, :on_apply
    end

    def canvas_panel
      Wx::Panel.new(book_ctrl) do |panel|
        panel.sizer = Wx::VBoxSizer.new do |vszr|

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Colours"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add Wx::VBoxSizer.new { |bgc_vszr|
              bgc_vszr.add(@rb_use_bgc = Wx::RadioButton.new(panel, Wx::ID_ANY, 'Use regular background colour', style: Wx::RB_GROUP),
                           Wx::SizerFlags.new.left.border(Wx::BOTTOM))
              bgc_vszr.add @use_bgc_szr = Wx::HBoxSizer.new { |hszr_|
                hszr_.add(Wx::StaticText.new(panel, :label => "Background colour:"), Wx::SizerFlags.new)
                hszr_.add(@bg_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                          Wx::SizerFlags.new.horz_border)
              }, Wx::SizerFlags.new.horz_border
            }, Wx::SizerFlags.new
            hszr.add Wx::VBoxSizer.new { |gbgc_vszr|
              gbgc_vszr.add(@rb_use_gbgc = Wx::RadioButton.new(panel, Wx::ID_ANY, 'Use gradient background colour'),
                            Wx::SizerFlags.new.left.border(Wx::BOTTOM))
              gbgc_vszr.add @use_gbgc_szr = Wx::HBoxSizer.new { |hszr_|
                hszr_.add(Wx::StaticText.new(panel, :label => "Gradient from:"), Wx::SizerFlags.new)
                hszr_.add(@gbg_from_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                          Wx::SizerFlags.new.horz_border)
                hszr_.add(Wx::StaticText.new(panel, :label => "to:"), Wx::SizerFlags.new)
                hszr_.add(@gbg_to_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                          Wx::SizerFlags.new.horz_border)
              }, Wx::SizerFlags.new.horz_border
            }, Wx::SizerFlags.new
          }, Wx::SizerFlags.new.border

          @bg_clr.colour = @canvas.get_canvas_colour
          @gbg_from_clr.colour = @canvas.get_gradient_from
          @gbg_to_clr.colour = @canvas.get_gradient_to
          @rb_use_gbgc.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::GRADIENT_BACKGROUND)

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Highlight colour:"), Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(@hover_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new.border(Wx::LEFT))
          }, Wx::SizerFlags.new.border

          @hover_clr.colour = @canvas.get_hover_colour

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Grid"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Grid size (px):"), Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(@grid_sz = Wx::SpinCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new.horz_border)
            hszr.add(Wx::StaticText.new(panel, :label => "Grid line multiplier:"), Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(@grid_ln_mult = Wx::SpinCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new.horz_border)
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(@cb_grid_show = Wx::CheckBox.new(panel, label: 'Show grid:', style: Wx::ALIGN_RIGHT), Wx::SizerFlags.new.border(Wx::LEFT, 3))
            hszr.add Wx::HBoxSizer.new { |hszr_|
              @grid_pen_szr = hszr_
              hszr_.add(Wx::StaticText.new(panel, :label => "Grid colour:"), Wx::SizerFlags.new.double_border(Wx::LEFT))
              hszr_.add(@grid_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                       Wx::SizerFlags.new.horz_border)
              hszr_.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Grid line style:'), Wx::SizerFlags.new)
              @grid_line_style = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                                  choices: get_enum_choices(
                                                    Wx::PenStyle,
                                                    excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE]))
              hszr_.add(@grid_line_style, Wx::SizerFlags.new.horz_border)
            }
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(@cb_grid_use = Wx::CheckBox.new(panel, label: 'Snap to grid:', style: Wx::ALIGN_RIGHT), Wx::SizerFlags.new.border(Wx::LEFT, 3))
          }, Wx::SizerFlags.new.border

          @grid_sz.value = @canvas.grid_size
          @grid_ln_mult.value = @canvas.grid_line_mult
          @grid_clr.colour = @canvas.grid_colour
          @grid_line_style.selection = pen_style_index(@canvas.grid_style)
          @cb_grid_show.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::GRID_SHOW)
          @cb_grid_use.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::GRID_USE)

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Shadows"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Shadow offset x:'), Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(@shadow_off_x = Wx::SpinCtrlDouble.new(panel, min: 0.0, inc: 1.0),
                     Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'y:'), Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(@shadow_off_y = Wx::SpinCtrlDouble.new(panel, min: 0.0, inc: 1.0),
                     Wx::SizerFlags.new.border(Wx::LEFT))
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Shadow colour:"), Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(@shadow_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Shadow style:'), Wx::SizerFlags.new.border(Wx::LEFT))
            @shadow_style = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                             choices: get_enum_choices(
                                               Wx::BrushStyle,
                                               excludes: EXCL_BRUSH_STYLES))
            hszr.add(@shadow_style, Wx::SizerFlags.new.border(Wx::LEFT))
          }, Wx::SizerFlags.new.border

          @shadow_off_x.value = @canvas.shadow_offset.x
          @shadow_off_y.value = @canvas.shadow_offset.y
          @shadow_clr.colour = @canvas.shadow_fill.colour
          @shadow_style.selection = brush_style_index(@canvas.shadow_fill.style)

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Scaling"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Minimum scale:'), Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(@min_scale = Wx::SpinCtrlDouble.new(panel, inc: 0.1),
                     Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Maximum scale:'), Wx::SizerFlags.new.border(Wx::LEFT))
            hszr.add(@max_scale = Wx::SpinCtrlDouble.new(panel, inc: 0.1),
                     Wx::SizerFlags.new.border(Wx::LEFT))
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(@cb_mouse_wheel_scale = Wx::CheckBox.new(panel, label: 'Mouse wheel scales:', style: Wx::ALIGN_RIGHT),
                     Wx::SizerFlags.new.border(Wx::LEFT, 3))
          }, Wx::SizerFlags.new.border

          @min_scale.set_range(0.1, @canvas.max_scale)
          @min_scale.value = @canvas.min_scale
          @max_scale.set_range(@canvas.min_scale, 100.0)
          @max_scale.value = @canvas.max_scale
          @cb_mouse_wheel_scale.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::PROCESS_MOUSEWHEEL)

        end
      end
    end

    def behaviour_panel
      Wx::Panel.new(book_ctrl) do |panel|
        panel.sizer = Wx::VBoxSizer.new do |vszr|

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Selection"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(@cb_hover_highlight = Wx::CheckBox.new(panel, label: 'Highlight shapes on hover:', style: Wx::ALIGN_RIGHT),
                     Wx::SizerFlags.new.border(Wx::LEFT, 3))
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(@cb_multi_select = Wx::CheckBox.new(panel, label: 'Allow selecting multiple shapes:', style: Wx::ALIGN_RIGHT),
                     Wx::SizerFlags.new.border(Wx::LEFT, 3))
            hszr.add(@cb_multi_resize = Wx::CheckBox.new(panel, label: 'Allow resizing multiple shapes:', style: Wx::ALIGN_RIGHT),
                     Wx::SizerFlags.new.border(Wx::LEFT, 3))
          }, Wx::SizerFlags.new.border

          @cb_hover_highlight.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::HOVERING)
          @cb_multi_select.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::MULTI_SELECTION)
          @cb_multi_resize.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::MULTI_SIZE_CHANGE)

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Editing"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(@cb_clipboard = Wx::CheckBox.new(panel, label: 'Enable Clipboard operations:', style: Wx::ALIGN_RIGHT),
                     Wx::SizerFlags.new.border(Wx::LEFT, 3))
            hszr.add(@cb_undo_redo = Wx::CheckBox.new(panel, label: 'Enable Undo/Redo operations:', style: Wx::ALIGN_RIGHT),
                     Wx::SizerFlags.new.border(Wx::LEFT, 3))
          }, Wx::SizerFlags.new.border

          @cb_clipboard.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::CLIPBOARD)
          @cb_undo_redo.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::UNDOREDO)

          if Wx.has_feature?(:USE_DRAG_AND_DROP)
            vszr.add Wx::HBoxSizer.new { |hszr|
              hszr.add(@cb_dnd = Wx::CheckBox.new(panel, label: 'Enable Drag&Drop operations:', style: Wx::ALIGN_RIGHT),
                       Wx::SizerFlags.new.border(Wx::LEFT, 3))
              hszr.add(@cb_drop_highlight = Wx::CheckBox.new(panel, label: 'Highlight when drop allowed:', style: Wx::ALIGN_RIGHT),
                       Wx::SizerFlags.new.border(Wx::LEFT, 3))
            }, Wx::SizerFlags.new.border

            @cb_dnd.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::DND)
            @cb_drop_highlight.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::HIGHLIGHTING)
          end

        end
      end
    end

    def print_panel
      Wx::Panel.new(book_ctrl) do |panel|
        panel.sizer = Wx::VBoxSizer.new do |vszr|

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Content"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(@cb_print_bg = Wx::CheckBox.new(panel, label: 'Print background:', style: Wx::ALIGN_RIGHT),
                     Wx::SizerFlags.new.border(Wx::LEFT, 3))
          }, Wx::SizerFlags.new.border

          @cb_print_bg.value = @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::PRINT_BACKGROUND)

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Printout"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Print mode:'), Wx::SizerFlags.new.border(Wx::LEFT))
            @print_mode = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                           choices: get_enum_choices(Wx::SF::ShapeCanvas::PRINTMODE))
            hszr.add(@print_mode, Wx::SizerFlags.new.border(Wx::LEFT))
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Horizontal alignment:'), Wx::SizerFlags.new.border(Wx::LEFT))
            @print_halign = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                           choices: get_enum_choices(Wx::SF::ShapeCanvas::HALIGN))
            hszr.add(@print_halign, Wx::SizerFlags.new.border(Wx::LEFT))
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Vertical alignment:'), Wx::SizerFlags.new.border(Wx::LEFT))
            @print_valign = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                             choices: get_enum_choices(Wx::SF::ShapeCanvas::VALIGN))
            hszr.add(@print_valign, Wx::SizerFlags.new.border(Wx::LEFT))
          }, Wx::SizerFlags.new.border

          @print_mode.selection = get_enum_index(@canvas.print_mode)
          @print_halign.selection = get_enum_index(@canvas.print_h_align)
          @print_valign.selection = get_enum_index(@canvas.print_v_align)

        end
      end
    end

    def shapes_panel
      Wx::Panel.new(book_ctrl) do |panel|
        panel.sizer = Wx::VBoxSizer.new do |vszr|

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Common"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Border colour:'), Wx::SizerFlags.new.border(Wx::RIGHT))
            hszr.add(@border_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                      Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Border width:'), Wx::SizerFlags.new.horz_border)
            hszr.add(@border_wdt = Wx::SpinCtrl.new(panel, Wx::ID_ANY),
                      Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Border style:'), Wx::SizerFlags.new.horz_border)
            @border_style = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                           choices: get_enum_choices(
                                             Wx::PenStyle,
                                             excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE]))
            hszr.add(@border_style, Wx::SizerFlags.new)
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Fill colour:'), Wx::SizerFlags.new.border(Wx::RIGHT))
            hszr.add(@fill_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Fill style:'), Wx::SizerFlags.new.horz_border)
            @fill_style = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                           choices: get_enum_choices(Wx::BrushStyle,
                                                                     excludes: EXCL_BRUSH_STYLES))
            hszr.add(@fill_style, Wx::SizerFlags.new)
          }, Wx::SizerFlags.new.border

          @border_clr.colour = @canvas.border_pen.colour
          @border_wdt.value = @canvas.border_pen.width
          @border_style.selection = pen_style_index(@canvas.border_pen.style)
          @fill_clr.colour = @canvas.fill_brush.colour
          @fill_style.selection = brush_style_index(@canvas.fill_brush.style)

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Text shapes"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Text colour:'), Wx::SizerFlags.new.border(Wx::RIGHT))
            hszr.add(@text_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Background colour:'), Wx::SizerFlags.new.border(Wx::RIGHT))
            hszr.add(@text_fill_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Background style:'), Wx::SizerFlags.new.horz_border)
            @text_fill_style = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                           choices: get_enum_choices(Wx::BrushStyle,
                                                                     excludes: EXCL_BRUSH_STYLES))
            hszr.add(@text_fill_style, Wx::SizerFlags.new)
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Border colour:'), Wx::SizerFlags.new.border(Wx::RIGHT))
            hszr.add(@text_border_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Border width:'), Wx::SizerFlags.new.horz_border)
            hszr.add(@text_border_wdt = Wx::SpinCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Border style:'), Wx::SizerFlags.new.horz_border)
            @text_border_style = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                             choices: get_enum_choices(
                                               Wx::PenStyle,
                                               excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE]))
            hszr.add(@text_border_style, Wx::SizerFlags.new)
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Font:'), Wx::SizerFlags.new.border(Wx::RIGHT))
            hszr.add(@text_font = Wx::FontPickerCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
          }, Wx::SizerFlags.new.border

          @text_clr.colour = @canvas.text_colour
          @text_border_clr.colour = @canvas.text_border.colour
          @text_border_wdt.value = @canvas.text_border.width
          @text_border_style.selection = pen_style_index(@canvas.text_border.style)
          @text_fill_clr.colour = @canvas.text_fill.colour
          @text_fill_style.selection = brush_style_index(@canvas.text_fill.style)
          @text_font.selected_font = @canvas.text_font

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Control shapes"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Background colour:'), Wx::SizerFlags.new.border(Wx::RIGHT))
            hszr.add(@ctrl_fill_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Background style:'), Wx::SizerFlags.new.horz_border)
            @ctrl_fill_style = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                                choices: get_enum_choices(Wx::BrushStyle,
                                                                          excludes: EXCL_BRUSH_STYLES))
            hszr.add(@ctrl_fill_style, Wx::SizerFlags.new)
          }, Wx::SizerFlags.new.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Border colour:'), Wx::SizerFlags.new.border(Wx::RIGHT))
            hszr.add(@ctrl_border_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Border width:'), Wx::SizerFlags.new.horz_border)
            hszr.add(@ctrl_border_wdt = Wx::SpinCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Border style:'), Wx::SizerFlags.new.horz_border)
            @ctrl_border_style = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                                  choices: get_enum_choices(
                                                    Wx::PenStyle,
                                                    excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE]))
            hszr.add(@ctrl_border_style, Wx::SizerFlags.new)
          }, Wx::SizerFlags.new.border
          vszr.add Wx::StaticBoxSizer.new(Wx::VERTICAL, panel, 'While modifying (resize, drag)') { |sb_vszr|
            sb_vszr.add Wx::HBoxSizer.new { |hszr|
              hszr.add(Wx::StaticText.new(sb_vszr.static_box, Wx::ID_ANY, 'Background colour:'), Wx::SizerFlags.new.border(Wx::RIGHT))
              hszr.add(@ctrl_mod_fill_clr = Wx::ColourPickerCtrl.new(sb_vszr.static_box, Wx::ID_ANY),
                       Wx::SizerFlags.new)
              hszr.add(Wx::StaticText.new(sb_vszr.static_box, Wx::ID_ANY, 'Background style:'), Wx::SizerFlags.new.horz_border)
              @ctrl_mod_fill_style = Wx::ComboBox.new(sb_vszr.static_box, Wx::ID_ANY,
                                                  choices: get_enum_choices(Wx::BrushStyle,
                                                                            excludes: EXCL_BRUSH_STYLES))
              hszr.add(@ctrl_mod_fill_style, Wx::SizerFlags.new)
            }, Wx::SizerFlags.new.border
            sb_vszr.add Wx::HBoxSizer.new { |hszr|
              hszr.add(Wx::StaticText.new(sb_vszr.static_box, Wx::ID_ANY, 'Border colour:'), Wx::SizerFlags.new.border(Wx::RIGHT))
              hszr.add(@ctrl_mod_border_clr = Wx::ColourPickerCtrl.new(sb_vszr.static_box, Wx::ID_ANY),
                       Wx::SizerFlags.new)
              hszr.add(Wx::StaticText.new(sb_vszr.static_box, Wx::ID_ANY, 'Border width:'), Wx::SizerFlags.new.horz_border)
              hszr.add(@ctrl_mod_border_wdt = Wx::SpinCtrl.new(sb_vszr.static_box, Wx::ID_ANY),
                       Wx::SizerFlags.new)
              hszr.add(Wx::StaticText.new(sb_vszr.static_box, Wx::ID_ANY, 'Border style:'), Wx::SizerFlags.new.horz_border)
              @ctrl_mod_border_style = Wx::ComboBox.new(sb_vszr.static_box, Wx::ID_ANY,
                                                    choices: get_enum_choices(
                                                      Wx::PenStyle,
                                                      excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE]))
              hszr.add(@ctrl_mod_border_style, Wx::SizerFlags.new)
            }, Wx::SizerFlags.new.border
          }, Wx::SizerFlags.new.border
          
          @ctrl_border_clr.colour = @canvas.control_border.colour
          @ctrl_border_wdt.value = @canvas.control_border.width
          @ctrl_border_style.selection = pen_style_index(@canvas.control_border.style)
          @ctrl_fill_clr.colour = @canvas.control_fill.colour
          @ctrl_fill_style.selection = brush_style_index(@canvas.control_fill.style)
          @ctrl_mod_border_clr.colour = @canvas.control_mod_border.colour
          @ctrl_mod_border_wdt.value = @canvas.control_mod_border.width
          @ctrl_mod_border_style.selection = pen_style_index(@canvas.control_mod_border.style)
          @ctrl_mod_fill_clr.colour = @canvas.control_mod_fill.colour
          @ctrl_mod_fill_style.selection = brush_style_index(@canvas.control_mod_fill.style)

          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, :label => "Line shapes"), Wx::SizerFlags.new)
            hszr.add(Wx::StaticLine.new(panel, size: [1,1]), Wx::SizerFlags.new(1).centre)
          }, Wx::SizerFlags.new.expand.border
          vszr.add Wx::HBoxSizer.new { |hszr|
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Line colour:'), Wx::SizerFlags.new.border(Wx::RIGHT))
            hszr.add(@line_clr = Wx::ColourPickerCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Line width:'), Wx::SizerFlags.new.horz_border)
            hszr.add(@line_wdt = Wx::SpinCtrl.new(panel, Wx::ID_ANY),
                     Wx::SizerFlags.new)
            hszr.add(Wx::StaticText.new(panel, Wx::ID_ANY, 'Line style:'), Wx::SizerFlags.new.horz_border)
            @line_style = Wx::ComboBox.new(panel, Wx::ID_ANY,
                                             choices: get_enum_choices(
                                               Wx::PenStyle,
                                               excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE]))
            hszr.add(@line_style, Wx::SizerFlags.new)
          }, Wx::SizerFlags.new.border
          
          @line_clr.colour = @canvas.line_pen.colour
          @line_wdt.value = @canvas.line_pen.width
          @line_style.selection = pen_style_index(@canvas.line_pen.style)

        end
      end
    end

    def update_canvas_style(set, style)
      if set then @canvas.add_style(style) else @canvas.remove_style(style) end
    end
    private :update_canvas_style

    def on_apply(evt)
      if @changed
        if @rb_use_bgc.value
          @canvas.remove_style(Wx::SF::ShapeCanvas::STYLE::GRADIENT_BACKGROUND)
          @canvas.canvas_colour = @bg_clr.colour
        else
          @canvas.add_style(Wx::SF::ShapeCanvas::STYLE::GRADIENT_BACKGROUND)
          @canvas.gradient_from = @gbg_from_clr.colour
          @canvas.gradient_to = @gbg_to_clr.colour
        end

        @canvas.hover_color = @hover_clr.colour

        @canvas.grid_size = @grid_sz.value
        @canvas.grid_line_mult = @grid_ln_mult.value
        @canvas.grid_colour = @grid_clr.colour
        @canvas.grid_style = selected_pen_style(@grid_line_style.selection)
        update_canvas_style(@cb_grid_show.value, Wx::SF::ShapeCanvas::STYLE::GRID_SHOW)
        update_canvas_style(@cb_grid_use.value, Wx::SF::ShapeCanvas::STYLE::GRID_USE)

        @canvas.shadow_offset = Wx::RealPoint.new(@shadow_off_x.value, @shadow_off_y.value)
        @canvas.set_shadow_fill(@shadow_clr.colour, @canvas.shadow_fill.style)

        @canvas.min_scale = @min_scale.value
        @canvas.max_scale = @max_scale.value
        update_canvas_style(@cb_mouse_wheel_scale.value, Wx::SF::ShapeCanvas::STYLE::PROCESS_MOUSEWHEEL)

        update_canvas_style(@cb_hover_highlight.value, Wx::SF::ShapeCanvas::STYLE::HOVERING)
        update_canvas_style(@cb_multi_select.value, Wx::SF::ShapeCanvas::STYLE::MULTI_SELECTION)
        update_canvas_style(@cb_multi_resize.value, Wx::SF::ShapeCanvas::STYLE::MULTI_SIZE_CHANGE)
        update_canvas_style(@cb_clipboard.value, Wx::SF::ShapeCanvas::STYLE::CLIPBOARD)
        update_canvas_style(@cb_undo_redo.value, Wx::SF::ShapeCanvas::STYLE::UNDOREDO)
        if Wx.has_feature?(:USE_DRAG_AND_DROP)
          update_canvas_style(@cb_dnd.value, Wx::SF::ShapeCanvas::STYLE::DND)
        end
        update_canvas_style(@cb_drop_highlight.value, Wx::SF::ShapeCanvas::STYLE::HIGHLIGHTING)

        update_canvas_style(@cb_print_bg.value, Wx::SF::ShapeCanvas::STYLE::PRINT_BACKGROUND)

        @canvas.print_mode = index_to_enum(Wx::SF::ShapeCanvas::PRINTMODE, @print_mode.selection)
        @canvas.print_h_align = index_to_enum(Wx::SF::ShapeCanvas::HALIGN, @print_halign.selection)
        @canvas.print_v_align = index_to_enum(Wx::SF::ShapeCanvas::HALIGN, @print_valign.selection)

        @canvas.set_border_pen(@border_clr.colour, @border_wdt.value, selected_pen_style(@border_style.selection))
        @canvas.set_fill_brush(@fill_clr.colour, selected_brush_style(@fill_style.selection))

        @canvas.text_colour = @text_clr.colour
        @canvas.set_text_border(@text_border_clr.colour, @text_border_wdt.value, selected_pen_style(@text_border_style.selection))
        @canvas.set_text_fill(@text_fill_clr.colour, selected_brush_style(@text_fill_style.selection))
        @canvas.text_font = @text_font.selected_font

        @canvas.set_control_border(@ctrl_border_clr.colour, @ctrl_border_wdt.value, selected_pen_style(@ctrl_border_style.selection))
        @canvas.set_control_fill(@ctrl_fill_clr.colour, selected_brush_style(@ctrl_fill_style.selection))
        @canvas.set_control_mod_border(@ctrl_mod_border_clr.colour, @ctrl_mod_border_wdt.value, selected_pen_style(@ctrl_mod_border_style.selection))
        @canvas.set_control_mod_fill(@ctrl_mod_fill_clr.colour, selected_brush_style(@ctrl_mod_fill_style.selection))

        @canvas.set_line_pen(@line_clr.colour, @line_wdt.value, selected_pen_style(@line_style.selection))

        @changed = false
        @canvas.invalidate_visible_rect
        @canvas.refresh_invalidated_rect
      end
      evt.skip
    end
    private :on_apply

    def on_update_ui(evt)
      case evt.id
      when Wx::ID_OK, Wx::ID_APPLY
        evt.event_object.enable(@changed)
      when @bg_clr.id
        @use_bgc_szr.each_child { |c| c.window.enable(@rb_use_bgc.value) }
      when @gbg_from_clr.id
        @use_gbgc_szr.each_child { |c| c.window.enable(@rb_use_gbgc.value) }
      when @grid_clr.id
        @grid_pen_szr.each_child { |c| c.window.enable(@cb_grid_show.value) }
      end
    end

    def on_change(evt)
      case evt.id
      when @rb_use_bgc.id
        @changed ||= @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::GRADIENT_BACKGROUND) == @rb_use_bgc.value
      when @rb_use_gbgc.id
        @changed ||= @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::GRADIENT_BACKGROUND) != @rb_use_gbgc.value
      when @bg_clr.id
        @changed ||= @bg_clr.colour != @canvas.canvas_colour
      when @gbg_from_clr.id
        @changed ||= @gbg_from_clr.colour != @canvas.gradient_from
      when @gbg_to_clr.id
        @changed ||= @gbg_to_clr.colour != @canvas.gradient_to
      when @hover_clr.id
        @changed ||= @hover_clr.color != @canvas.hover_color
      when @grid_sz.id
        @changed ||= @grid_sz.value != @canvas.grid_size
      when @grid_ln_mult.id
        @changed ||= @grid_ln_mult.value != @canvas.grid_line_mult
      when @cb_grid_show.id
        @changed ||= @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::GRID_SHOW) != @cb_grid_show.value
      when @cb_grid_use.id
        @changed ||= @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::GRID_USE) != @cb_grid_use.value
      when @grid_clr.id
        @changed ||= @grid_clr.colour != @canvas.grid_colour
      when @grid_line_style.id
        @changed ||= selected_pen_style(@grid_line_style.selection) != @canvas.grid_style
      when @shadow_clr.id
        @changed ||= @shadow_clr.colour != @canvas.shadow_fill.colour
      when @shadow_off_x.id
        @changed ||= @shadow_off_x.value != @canvas.shadow_offset.x
      when @shadow_off_y.id
        @changed ||= @shadow_off_y.value != @canvas.shadow_offset.y
      when @shadow_style.id
        @changed ||= selected_brush_style(@shadow_style.selection) != @canvas.shadow_fill.style
      when @min_scale.id
        @changed ||= @min_scale.value != @canvas.min_scale
        @max_scale.set_range(@min_scale.value, 100.0)
      when @max_scale.id
        @changed ||= @max_scale.value != @canvas.max_scale
        @min_scale.set_range(0.1, @max_scale.value)
      when @cb_mouse_wheel_scale.id
        @changed ||= @cb_mouse_wheel_scale.value != @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::PROCESS_MOUSEWHEEL)
      when @cb_hover_highlight.id
        @changed ||= @cb_hover_highlight.value != @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::HOVERING)
      when @cb_multi_select.id
        @changed ||= @cb_multi_select.value != @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::MULTI_SELECTION)
      when @cb_multi_resize.id
        @changed ||= @cb_multi_resize.value != @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::MULTI_SIZE_CHANGE)
      when @cb_clipboard.id
        @changed ||= @cb_clipboard.value != @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::CLIPBOARD)
      when @cb_undo_redo.id
        @changed ||= @cb_undo_redo.value != @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::UNDOREDO)
      when @cb_drop_highlight.id
        @changed ||= @cb_drop_highlight.value != @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::HIGHLIGHTING)
      when @cb_print_bg.id
        @changed ||= @cb_print_bg.value != @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::PRINT_BACKGROUND)
      when @print_mode.id
        @changed ||= @print_mode.selection != get_enum_index(@canvas.print_mode)
      when @print_halign.id
        @changed ||= @print_halign.selection != get_enum_index(@canvas.print_h_align)
      when @print_valign.id
        @changed ||= @print_valign.selection != get_enum_index(@canvas.print_v_align)
      when @border_clr.id
        @changed ||= @border_clr.colour != @canvas.border_pen.colour
      when @border_wdt.id
        @changed ||= @border_wdt.value != @canvas.border_pen.width
      when @border_style.id
        @changed ||= @border_style.selection = pen_style_index(@canvas.border_pen.style)
      when @fill_clr.id
        @changed ||= @fill_clr.colour != @canvas.fill_brush.colour
      when @fill_style.id
        @changed ||= @fill_style.selection = brush_style_index(@canvas.fill_brush.style)
      when @text_clr.id
        @changed ||= @text_clr.colour != @canvas.text_colour
      when @text_border_clr.id
        @changed ||= @text_border_clr.colour != @canvas.text_border.colour
      when @text_border_wdt.id
        @changed ||= @text_border_wdt.value != @canvas.text_border.width
      when @text_border_style.id
        @changed ||= @text_border_style.selection != pen_style_index(@canvas.text_border.style)
      when @text_fill_clr.id
        @changed ||= @text_fill_clr.colour != @canvas.text_fill.colour
      when @text_fill_style.id
        @changed ||= @text_fill_style.selection != brush_style_index(@canvas.text_fill.style)
      when @text_font.id
        @changed ||= @text_font.selected_font != @canvas.text_font
      when @ctrl_border_clr.id
        @changed ||= @ctrl_border_clr.colour != @canvas.control_border.colour
      when @ctrl_border_wdt.id
        @changed ||= @ctrl_border_wdt.value != @canvas.control_border.width
      when @ctrl_border_style.id
        @changed ||= @ctrl_border_style.selection != pen_style_index(@canvas.control_border.style)
      when @ctrl_fill_clr.id
        @changed ||= @ctrl_fill_clr.colour != @canvas.control_fill.colour
      when @ctrl_fill_style.id
        @changed ||= @ctrl_fill_style.selection != brush_style_index(@canvas.control_fill.style)
      when @ctrl_mod_border_clr.id
        @changed ||= @ctrl_mod_border_clr.colour != @canvas.control_mod_border.colour
      when @ctrl_mod_border_wdt.id
        @changed ||= @ctrl_mod_border_wdt.value != @canvas.control_mod_border.width
      when @ctrl_mod_border_style.id
        @changed ||= @ctrl_mod_border_style.selection != pen_style_index(@canvas.control_mod_border.style)
      when @ctrl_mod_fill_clr.id
        @changed ||= @ctrl_mod_fill_clr.colour != @canvas.control_mod_fill.colour
      when @ctrl_mod_fill_style.id
        @changed ||= @ctrl_mod_fill_style.selection != brush_style_index(@canvas.control_mod_fill.style)
      when @line_clr.id
        @changed ||= @line_clr.colour != @canvas.line_pen.colour
      when @line_wdt.id
        @changed ||= @line_wdt.value != @canvas.line_pen.width
      when @line_style.id
        @changed ||= @line_style.selection != pen_style_index(@canvas.line_pen.style)
      else
        if Wx.has_feature?(:USE_DRAG_AND_DROP) &&  evt.id == @cb_dnd.id
          @changed ||= @cb_dnd.value != @canvas.has_style?(Wx::SF::ShapeCanvas::STYLE::DND)
        end
      end
    end

    def pen_style_index(style)
      get_enum_index(style,
                     excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE])
    end
    private :pen_style_index

    def selected_pen_style(index)
      index_to_enum(Wx::PenStyle,
                    index,
                    excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE])
    end
    private :selected_pen_style

    def brush_style_index(style)
      get_enum_index(style,
                     excludes: EXCL_BRUSH_STYLES)
    end
    private :brush_style_index

    def selected_brush_style(index)
      index_to_enum(Wx::BrushStyle,
                    index,
                    excludes: EXCL_BRUSH_STYLES)
    end
    private :selected_brush_style

    def get_enum_choices(enum, excludes: nil)
      Dialogs.get_enum_choices(enum, excludes: excludes)
    end
    private :get_enum_choices

    def get_enum_index(enumerator, excludes: nil)
      Dialogs.get_enum_index(enumerator, excludes: excludes)
    end
    private :get_enum_index

    def index_to_enum(enum, index, excludes: nil)
      Dialogs.index_to_enum(enum, index, excludes: excludes)
    end
    private :index_to_enum

  end

  EXCL_BRUSH_STYLES = [
    :BRUSHSTYLE_INVALID,
    :BRUSHSTYLE_STIPPLE,
    :BRUSHSTYLE_STIPPLE_MASK,
    :BRUSHSTYLE_STIPPLE_MASK_OPAQUE,
    :BRUSHSTYLE_FIRST_HATCH,
    :BRUSHSTYLE_LAST_HATCH
  ]

  class FloatDialog < Wx::Dialog
    def initialize(parent, title, label: 'Value:', value: 0.0, min: 0.0, max: 100.0, inc: 1.0)
      super(parent, Wx::ID_ANY, title, size: [400, -1])
      sizer_top = Wx::VBoxSizer.new do |vszr|
        vszr.add Wx::HBoxSizer.new { |hszr|
          hszr.add(Wx::StaticText.new(self, Wx::ID_ANY, label), Wx::SizerFlags.new.border(Wx::ALL, 5))
          @spin_ctrl = Wx::SpinCtrlDouble.new(self, Wx::ID_ANY, value.to_s, min: min, max: max, inc: inc)
          hszr.add(@spin_ctrl, Wx::SizerFlags.new.border(Wx::ALL, 5))
        }, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::ALL, 5)
        vszr.add Wx::HBoxSizer.new { |hszr|
          hszr.add(Wx::Button.new(self, Wx::ID_OK, "&Ok"), Wx::SizerFlags.new.border(Wx::ALL, 5))
          hszr.add(Wx::Button.new(self, Wx::ID_CANCEL, "&Cancel"), Wx::SizerFlags.new.border(Wx::ALL, 5))
        }, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::RIGHT, 80)
      end
      set_auto_layout(true)
      set_sizer(sizer_top)

      sizer_top.set_size_hints(self)
      sizer_top.fit(self)
    end

    def get_value
      @spin_ctrl.get_value
    end
  end

  class ConnectionPointDialog < Wx::Dialog

    def initialize(parent, conn_pts)
      super(parent, Wx::ID_ANY, 'Change connection points')
      sizer_top = Wx::VBoxSizer.new

      sizer = Wx::HBoxSizer.new
      vszr = Wx::VBoxSizer.new
      vszr.add(Wx::StaticText.new(self, Wx::ID_ANY, 'Connection points:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @lst_view = Wx::ListView.new(self)
      @lst_view.append_column("Connection type",Wx::LIST_FORMAT_LEFT, Wx::LIST_AUTOSIZE_USEHEADER)
      @lst_view.append_column("Id",Wx::LIST_FORMAT_LEFT, Wx::LIST_AUTOSIZE_USEHEADER)
      @lst_view.append_column("Otho direction",Wx::LIST_FORMAT_LEFT, Wx::LIST_AUTOSIZE_USEHEADER)
      @lst_view.append_column("Rel position",Wx::LIST_FORMAT_LEFT, Wx::LIST_AUTOSIZE_USEHEADER)

      (@cpts = conn_pts.dup).each do |cpt|
        add_list_item(cpt)
      end

      vszr.add(@lst_view, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(vszr, Wx::SizerFlags.new.border(Wx::ALL, 5))

      vszr = Wx::VBoxSizer.new
      @cpt_szr = Wx::StaticBoxSizer.new(Wx::Orientation::VERTICAL, self, 'Connection point')
      hszr = Wx::HBoxSizer.new
      hszr.add(Wx::StaticText.new(@cpt_szr.static_box, Wx::ID_ANY, 'Type:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @cpt_type = Wx::ComboBox.new(@cpt_szr.static_box, Wx::ID_ANY,
                                   choices: get_enum_choices(Wx::SF::ConnectionPoint::CPTYPE))
      hszr.add(@cpt_type, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @cpt_szr.add(hszr, Wx::SizerFlags.new.border(Wx::ALL, 5))

      hszr = Wx::HBoxSizer.new
      hszr.add(Wx::StaticText.new(@cpt_szr.static_box, Wx::ID_ANY, 'Id:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @cpt_id = Wx::TextCtrl.new(@cpt_szr.static_box, validator: Wx::TextValidator.new(Wx::TextValidatorStyle::FILTER_DIGITS))
      @cpt_id.enable(false)
      hszr.add(@cpt_id, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @cpt_szr.add(hszr, Wx::SizerFlags.new.border(Wx::ALL, 5))

      hszr = Wx::HBoxSizer.new
      hszr.add(Wx::StaticText.new(@cpt_szr.static_box, Wx::ID_ANY, 'Orthogonal direction:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @cpt_odir = Wx::ComboBox.new(@cpt_szr.static_box, Wx::ID_ANY,
                                   choices: get_enum_choices(Wx::SF::ConnectionPoint::CPORTHODIR))
      hszr.add(@cpt_odir, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @cpt_szr.add(hszr, Wx::SizerFlags.new.border(Wx::ALL, 5))

      hszr = Wx::HBoxSizer.new
      hszr.add(Wx::StaticText.new(@cpt_szr.static_box, Wx::ID_ANY, 'Relative position x:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @rpos_x = Wx::SpinCtrlDouble.new(@cpt_szr.static_box, Wx::ID_ANY, min: 0.0, inc: 1.0)
      hszr.add(@rpos_x, Wx::SizerFlags.new.border(Wx::ALL, 5))
      hszr.add(Wx::StaticText.new(@cpt_szr.static_box, Wx::ID_ANY, 'y:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @rpos_y = Wx::SpinCtrlDouble.new(@cpt_szr.static_box, Wx::ID_ANY, min: 0.0, inc: 1.0)
      hszr.add(@rpos_y, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @cpt_szr.add(hszr, Wx::SizerFlags.new.border(Wx::ALL, 5))

      hszr = Wx::HBoxSizer.new
      @add_btn = Wx::Button.new(@cpt_szr.static_box, Wx::ID_ANY, 'Add')
      @add_btn.enable(false)
      hszr.add(@add_btn, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @chg_btn = Wx::Button.new(@cpt_szr.static_box, Wx::ID_ANY, 'Change selected')
      hszr.add(@chg_btn, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @chg_btn.enable(false)
      @cpt_szr.add(hszr, Wx::SizerFlags.new.border(Wx::ALL, 5))

      vszr.add(@cpt_szr, Wx::SizerFlags.new.border(Wx::ALL, 5))

      hszr = Wx::HBoxSizer.new
      @del_btn = Wx::Button.new(self, Wx::ID_ANY, 'Delete selected')
      @del_btn.enable(false)
      hszr.add(@del_btn, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @clear_btn = Wx::Button.new(self, Wx::ID_ANY, 'Delete all')
      @clear_btn.enable(!@cpts.empty?)
      hszr.add(@clear_btn, Wx::SizerFlags.new.border(Wx::ALL, 5))
      vszr.add(hszr, Wx::SizerFlags.new.border(Wx::ALL, 5))

      sizer.add(vszr, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_CENTRE_HORIZONTAL).border(Wx::ALL, 5))


      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::Button.new(self, Wx::ID_OK, "&Ok"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::Button.new(self, Wx::ID_CANCEL, "&Cancel"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::RIGHT, 80))

      set_auto_layout(true)
      set_sizer(sizer_top)

      sizer_top.set_size_hints(self)
      sizer_top.fit(self)

      evt_update_ui @cpt_type, :on_cpt_type_update
      evt_update_ui @add_btn, :on_add_cpt_update
      evt_update_ui @del_btn, :on_del_cpt_update
      evt_update_ui @chg_btn, :on_chg_cpt_update
      evt_update_ui(@clear_btn) { @clear_btn.enable(!@cpts.empty?) }
      evt_list_item_selected @lst_view, :on_list_item_selected
      evt_button @del_btn, :on_delete_cpt
      evt_button @chg_btn, :on_change_cpt
      evt_button @add_btn, :on_add_cpt
      evt_button(@clear_btn) { @lst_view.delete_all_items; @cpts.clear }
    end

    def set_shape_connection_points(shape)
      @cpts.each { |cpt| cpt.set_parent_shape(shape) }
      shape.connection_points.replace(@cpts)
    end

    def on_cpt_type_update(_evt)
      @cpt_id.enable(@cpt_type.string_selection == 'CUSTOM')
    end
    private :on_cpt_type_update

    def on_add_cpt_update(_evt)
      @add_btn.enable(@cpt_type.selection != -1 && @cpt_odir.selection != -1)
    end
    private :on_add_cpt_update

    def on_del_cpt_update(_evt)
      @del_btn.enable(@lst_view.get_selected_item_count > 0)
    end
    private :on_del_cpt_update

    def on_chg_cpt_update(_evt)
      @chg_btn.enable(@lst_view.get_selected_item_count == 1)
    end
    private :on_chg_cpt_update

    def on_list_item_selected(evt)
      sel_cpt = @cpts[evt.index]
      @cpt_type.set_selection(Wx::SF::ConnectionPoint::CPTYPE.enumerators.keys.index(sel_cpt.type.to_i))
      @cpt_id.value = sel_cpt.id.to_s
      @cpt_odir.set_selection(Wx::SF::ConnectionPoint::CPORTHODIR.enumerators.keys.index(sel_cpt.ortho_direction.to_i))
      @rpos_x.value = sel_cpt.relative_position.x
      @rpos_y.value = sel_cpt.relative_position.y
    end
    private :on_list_item_selected

    def on_delete_cpt(_evt)
      @lst_view.each_selected.reverse_each do |sel|
        @lst_view.delete_item(sel)
        @cpts.delete_at(sel)
      end
    end
    private :on_delete_cpt

    def update_connection_point(cpt)
      cpt.type = index_to_enum(Wx::SF::ConnectionPoint::CPTYPE, @cpt_type.selection)
      cpt.id = (@cpt_type.string_selection == 'CUSTOM' && !@cpt_id.value.empty?) ? @cpt_id.value.to_i : nil
      cpt.ortho_direction = index_to_enum(Wx::SF::ConnectionPoint::CPORTHODIR, @cpt_odir.selection)
      cpt.relative_position = Wx::RealPoint.new(@rpos_x.value, @rpos_y.value)
    end
    private :update_connection_point

    def update_list_item(item)
      @lst_view.set_item(item, 0, Wx::SF::ConnectionPoint::CPTYPE.enumerators[@cpts[item].type.to_i].to_s)
      @lst_view.set_item(item, 1, @cpts[item].id.to_s)
      @lst_view.set_item(item, 2, Wx::SF::ConnectionPoint::CPORTHODIR.enumerators[@cpts[item].ortho_direction.to_i].to_s)
      @lst_view.set_item(item, 3, '%.2f x %.2f' % @cpts[item].relative_position.to_ary)
    end
    private :update_list_item

    def on_change_cpt(_evt)
      unless (sel = @lst_view.get_first_selected) == -1
        update_connection_point(@cpts[sel])
        update_list_item(sel)
      end
    end
    private :on_change_cpt

    def add_list_item(cpt)
      item = @lst_view.insert_item(@lst_view.item_count, Wx::SF::ConnectionPoint::CPTYPE.enumerators[cpt.type.to_i].to_s)
      @lst_view.set_item(item, 1, cpt.id.to_s)
      @lst_view.set_item(item, 2, Wx::SF::ConnectionPoint::CPORTHODIR.enumerators[cpt.ortho_direction.to_i].to_s)
      @lst_view.set_item(item, 3, '%.2f x %.2f' % cpt.relative_position.to_ary)
    end
    private :add_list_item

    def on_add_cpt(_evt)
      @cpts << Wx::SF::ConnectionPoint.new
      update_connection_point(@cpts.last)
      add_list_item(@cpts.last)
    end

    def get_enum_choices(enum, excludes: nil)
      Dialogs.get_enum_choices(enum, excludes: excludes)
    end
    private :get_enum_choices

    def get_enum_index(enumerator, excludes: nil)
      Dialogs.get_enum_index(enumerator, excludes: excludes)
    end
    private :get_enum_index

    def index_to_enum(enum, index, excludes: nil)
      Dialogs.index_to_enum(enum, index, excludes: excludes)
    end
    private :index_to_enum

  end

  class AcceptedShapesDialog < Wx::Dialog

    def initialize(parent, message, selectable_shapes, accepted_shapes)
      super(parent, Wx::ID_ANY, 'Select shapes')
      sizer_top = Wx::VBoxSizer.new

      sizer_top.add(Wx::StaticText.new(self, Wx::ID_ANY, message), Wx::SizerFlags.new.border(Wx::ALL, 5))

      sizer = Wx::HBoxSizer.new
      @none_rb = Wx::RadioButton.new(self, Wx::ID_ANY, 'Accept NONE', style: Wx::RB_GROUP)
      sizer.add(@none_rb, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @all_rb = Wx::RadioButton.new(self, Wx::ID_ANY, 'Accept ALL')
      sizer.add(@all_rb, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @some_rb = Wx::RadioButton.new(self, Wx::ID_ANY, 'Accept selection')
      sizer.add(@some_rb, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.border(Wx::ALL, 5))

      sizer = Wx::HBoxSizer.new
      @lbox = Wx::CheckListBox.new(self, Wx::ID_ANY, choices: get_shape_choices(selectable_shapes))
      sizer.add(@lbox, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_CENTRE_HORIZONTAL).border(Wx::ALL, 5))

      if accepted_shapes.empty?
        @none_rb.value = true
        @lbox.enable(false)
      elsif accepted_shapes.include?(Wx::SF::ACCEPT_ALL)
        @all_rb.value = true
        @lbox.enable(false)
      else
        @some_rb.value = true
        get_shape_selections(selectable_shapes, accepted_shapes).each { |ix| @lbox.check(ix, true) }
      end

      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::Button.new(self, Wx::ID_OK, "&Ok"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::Button.new(self, Wx::ID_CANCEL, "&Cancel"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::RIGHT, 80))

      set_auto_layout(true)
      set_sizer(sizer_top)

      sizer_top.set_size_hints(self)
      sizer_top.fit(self)

      evt_radiobutton Wx::ID_ANY, :on_radiobutton
    end

    def get_shape_choices(shapes)
      shapes.collect { |c| c.name }
    end

    def get_shape_selections(shapes, accepted_shapes)
      accepted_shapes.collect { |ac| shapes.index(ac) }
    end

    def get_selected_shapes(selectable_shapes)
      if @none_rb.value
        nil
      elsif @all_rb.value
        [Wx::SF::ACCEPT_ALL]
      else
        sel = @lbox.get_checked_items.collect { |ix| selectable_shapes[ix] }
        sel.empty? ? nil : sel
      end
    end

    def on_radiobutton(_evt)
      @lbox.enable(@some_rb.value)
    end
    private :on_radiobutton

  end

  class BrushDialog < Wx::Dialog

    def initialize(parent, title, brush)
      super(parent, Wx::ID_ANY, title)
      sizer_top = Wx::VBoxSizer.new

      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::StaticText.new(self, Wx::ID_ANY, 'Colour:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @fill_clr = Wx::ColourPickerCtrl.new(self, Wx::ID_ANY)
      sizer.add(@fill_clr, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::StaticText.new(self, Wx::ID_ANY, 'Style:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @fill_style = Wx::ComboBox.new(self, Wx::ID_ANY,
                                     choices: get_enum_choices(Wx::BrushStyle,
                                                               excludes: EXCL_BRUSH_STYLES))
      sizer.add(@fill_style, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.border(Wx::ALL, 5))

      @fill_clr.colour = brush.colour
      @fill_style.selection = get_enum_index(brush.style,
                                             excludes: EXCL_BRUSH_STYLES)

      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::Button.new(self, Wx::ID_OK, "&Ok"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::Button.new(self, Wx::ID_CANCEL, "&Cancel"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::RIGHT, 80))

      set_auto_layout(true)
      set_sizer(sizer_top)

      sizer_top.set_size_hints(self)
      sizer_top.fit(self)
    end

    def get_brush
      Wx::Brush.new(@fill_clr.colour,
                    index_to_enum(Wx::BrushStyle, @fill_style.selection,
                                  excludes: EXCL_BRUSH_STYLES))
    end

    def get_enum_choices(enum, excludes: nil)
      Dialogs.get_enum_choices(enum, excludes: excludes)
    end
    private :get_enum_choices

    def get_enum_index(enumerator, excludes: nil)
      Dialogs.get_enum_index(enumerator, excludes: excludes)
    end
    private :get_enum_index

    def index_to_enum(enum, index, excludes: nil)
      Dialogs.index_to_enum(enum, index, excludes: excludes)
    end
    private :index_to_enum

  end

  class PenDialog < Wx::Dialog

    def initialize(parent, title, pen)
      super(parent, Wx::ID_ANY, title)
      sizer_top = Wx::VBoxSizer.new

      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::StaticText.new(self, Wx::ID_ANY, 'Colour:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @line_clr = Wx::ColourPickerCtrl.new(self, Wx::ID_ANY)
      sizer.add(@line_clr, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::StaticText.new(self, Wx::ID_ANY, 'Width:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @line_wdt = Wx::SpinCtrl.new(self, Wx::ID_ANY)
      sizer.add(@line_wdt, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::StaticText.new(self, Wx::ID_ANY, 'Style:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @line_style = Wx::ComboBox.new(self, Wx::ID_ANY,
                                     choices: get_enum_choices(Wx::PenStyle,
                                                               excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE]))
      sizer.add(@line_style, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::ALL, 5))

      @line_clr.colour = pen.colour
      @line_wdt.value = pen.width
      @line_style.selection = get_enum_index(pen.style,
                                             excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE])

      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::Button.new(self, Wx::ID_OK, "&Ok"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::Button.new(self, Wx::ID_CANCEL, "&Cancel"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::RIGHT, 80))

      set_auto_layout(true)
      set_sizer(sizer_top)

      sizer_top.set_size_hints(self)
      sizer_top.fit(self)
    end

    def get_pen
      Wx::Pen.new(@line_clr.colour, @line_wdt.value,
                  index_to_enum(Wx::PenStyle, @line_style.selection,
                                excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE]))
    end

    def get_enum_choices(enum, excludes: nil)
      Dialogs.get_enum_choices(enum, excludes: excludes)
    end
    private :get_enum_choices

    def get_enum_index(enumerator, excludes: nil)
      Dialogs.get_enum_index(enumerator, excludes: excludes)
    end
    private :get_enum_index

    def index_to_enum(enum, index, excludes: nil)
      Dialogs.index_to_enum(enum, index, excludes: excludes)
    end
    private :index_to_enum

  end

  class ArrowDialog < Wx::Dialog

    def initialize(parent, title, arrow)
      super(parent, Wx::ID_ANY, title)
      sizer_top = Wx::VBoxSizer.new

      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::StaticText.new(self, Wx::ID_ANY, 'Arrow type:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @arrow = Wx::ComboBox.new(self, Wx::ID_ANY, arrow_type(arrow),
                                choices: %w[None Open Prong Crossbar DoubleCrossbar Cup Solid Diamond Circle Square CrossBarCircle CrossBarProng CircleProng CrossedCircle])
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
                                     choices: get_enum_choices(Wx::PenStyle,
                                                               excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE]))
      sizer.add(@line_style, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @line_szr.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::ALL, 5))
      sizer_top.add(@line_szr, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).border(Wx::ALL, 5))

      if Wx::SF::LineArrow === arrow
        @line_pen_rb.value = true
        @line_clr.colour = arrow.pen.colour
        @line_wdt.value = arrow.pen.width
        @line_style.selection = get_enum_index(arrow.pen.style,
                                               excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE])
        @line_clr.enable(false)
        @line_wdt.enable(false)
        @line_style.enable(false)
      else
        @line_szr.static_box.enable(false)
      end

      @fill_szr = Wx::StaticBoxSizer.new(Wx::Orientation::VERTICAL, self, 'Fill')
      sizer = Wx::HBoxSizer.new
      @def_brush_rb = Wx::RadioButton.new(@fill_szr.static_box, Wx::ID_ANY, 'Use default brush', style: Wx::RB_GROUP)
      sizer.add(@def_brush_rb, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @custom_brush_rb = Wx::RadioButton.new(@fill_szr.static_box, Wx::ID_ANY, 'Use custom brush')
      sizer.add(@custom_brush_rb, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @fill_szr.add(sizer, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::StaticText.new(@fill_szr.static_box, Wx::ID_ANY, 'Colour:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @fill_clr = Wx::ColourPickerCtrl.new(@fill_szr.static_box, Wx::ID_ANY)
      sizer.add(@fill_clr, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer.add(Wx::StaticText.new(@fill_szr.static_box, Wx::ID_ANY, 'Style:'), Wx::SizerFlags.new.border(Wx::ALL, 5))
      @fill_style = Wx::ComboBox.new(@fill_szr.static_box, Wx::ID_ANY,
                                     choices: get_enum_choices(Wx::BrushStyle,
                                                               excludes: EXCL_BRUSH_STYLES))
      sizer.add(@fill_style, Wx::SizerFlags.new.border(Wx::ALL, 5))
      @fill_szr.add(sizer, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(@fill_szr, Wx::SizerFlags.new.align(Wx::ALIGN_LEFT).expand.border(Wx::ALL, 5))

      if Wx::SF::FilledArrow === arrow
        @def_brush_rb.value = true
        @fill_clr.colour = arrow.fill.colour
        @fill_style.selection = get_enum_index(arrow.fill.style,
                                               excludes: EXCL_BRUSH_STYLES)
        @fill_clr.enable(false)
        @fill_style.enable(false)
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
      when 'Open', 'Cup', 'Prong', 'Crossbar', 'DoubleCrossbar', 'CrossBarProng'
        arrow = case @arrow.get_value
                when 'Open' then Wx::SF::OpenArrow.new
                when 'Prong' then Wx::SF::ProngArrow.new
                when 'Cup' then Wx::SF::CupArrow.new
                when 'Crossbar' then Wx::SF::CrossBarArrow.new
                when 'DoubleCrossbar' then Wx::SF::DoubleCrossBarArrow.new
                when 'CrossBarProng' then Wx::SF::CrossBarProngArrow.new
                end
        if @custom_pen_rb.value
          arrow.set_pen(Wx::Pen.new(@line_clr.colour, @line_wdt.value,
                                    index_to_enum(Wx::PenStyle, @line_style.selection,
                                                  excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE])))
        end
        arrow
      else
        arrow = case @arrow.get_value
                when 'Solid' then Wx::SF::SolidArrow.new
                when 'Diamond' then Wx::SF::DiamondArrow.new
                when 'Circle' then Wx::SF::CircleArrow.new
                when 'Square' then Wx::SF::SquareArrow.new
                when 'CrossBarCircle' then Wx::SF::CrossBarCircleArrow.new
                when 'CircleProng' then Wx::SF::CircleProngArrow.new
                when 'CrossedCircle' then Wx::SF::CrossedCircleArrow.new
                end
        if @custom_pen_rb.value
          arrow.set_pen(Wx::Pen.new(@line_clr.colour, @line_wdt.value,
                                    index_to_enum(Wx::PenStyle, @line_style.selection,
                                                  excludes: %i[PENSTYLE_INVALID PENSTYLE_FIRST_HATCH PENSTYLE_LAST_HATCH PENSTYLE_STIPPLE])))
        end
        if @custom_brush_rb.value
          arrow.set_fill(Wx::Brush.new(@fill_clr.colour,
                                       index_to_enum(Wx::BrushStyle, @fill_style.selection,
                                                     excludes: EXCL_BRUSH_STYLES)))
        end
        arrow
      end
    end

    def arrow_type(arrow)
      case arrow
      when Wx::SF::CrossBarProngArrow then 'CrossBarProng'
      when Wx::SF::ProngArrow then 'Prong'
      when Wx::SF::OpenArrow then 'Open'
      when Wx::SF::CupArrow then 'Cup'
      when Wx::SF::DoubleCrossBarArrow then 'DoubleCrossbar'
      when Wx::SF::CrossBarArrow then 'Crossbar'
      when Wx::SF::DiamondArrow then 'Diamond'
      when Wx::SF::SquareArrow then 'Square'
      when Wx::SF::SolidArrow then 'Solid'
      when Wx::SF::CrossedCircleArrow then 'CrossedCircle'
      when Wx::SF::CircleProngArrow then 'CircleProng'
      when Wx::SF::CrossBarCircleArrow then 'CrossBarCircle'
      when Wx::SF::CircleArrow then 'Circle'
      else
        'None'
      end
    end
    private :arrow_type

    def get_enum_choices(enum, excludes: nil)
      Dialogs.get_enum_choices(enum, excludes: excludes)
    end
    private :get_enum_choices

    def get_enum_index(enumerator, excludes: nil)
      Dialogs.get_enum_index(enumerator, excludes: excludes)
    end
    private :get_enum_index

    def index_to_enum(enum, index, excludes: nil)
      Dialogs.index_to_enum(enum, index, excludes: excludes)
    end
    private :index_to_enum

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
      if @def_brush_rb.value
        @fill_clr.enable(false)
        @fill_style.enable(false)
      else
        @fill_clr.enable(true)
        @fill_style.enable(true)
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
        when 'Open', 'Prong', 'Cup', 'Crossbar', 'DoubleCrossbar', 'CrossBarProng'
          @fill_szr.static_box.enable(false)
        else
          @fill_szr.static_box.enable(true)
        end
      end
    end
    protected :get_enum_choices

  end

  class StateDialog < Wx::Dialog

    def initialize(parent, shape)
      super(parent, title: "State of #{shape}")
      sizer_top = Wx::VBoxSizer.new

      sizer = Wx::HBoxSizer.new
      text = Wx::TextCtrl.new(self, size: [500, 350], style: Wx::TE_MULTILINE|Wx::TE_READONLY|Wx::HSCROLL)
      txt_attr = text.get_default_style
      txt_attr.font = Wx::Font.new(Wx::FontInfo.new(10.0).family(Wx::FontFamily::FONTFAMILY_TELETYPE))
      text.set_default_style(txt_attr)
      text.set_value(shape.serialize(format: :yaml))
      sizer.add(text, Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new)

      sizer = Wx::HBoxSizer.new
      sizer.add(Wx::Button.new(self, Wx::ID_OK, "&Ok"), Wx::SizerFlags.new.border(Wx::ALL, 5))
      sizer_top.add(sizer, Wx::SizerFlags.new.align(Wx::ALIGN_RIGHT).border(Wx::LEFT, 80))

      set_auto_layout(true)
      set_sizer(sizer_top)

      sizer_top.set_size_hints(self)
      sizer_top.fit(self)
    end

  end

end
