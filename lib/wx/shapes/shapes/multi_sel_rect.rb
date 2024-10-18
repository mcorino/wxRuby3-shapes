# Wx::SF::MultiSelRect - multi-sel rect shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'

module Wx::SF

  class MultiSelRect < RectShape

    # Default constructor.
    def initialize
      super
      set_border(Wx::Pen.new(Wx::Colour.new(100, 100, 100), 1, Wx::PenStyle::PENSTYLE_DOT))
      set_fill(Wx::TRANSPARENT_BRUSH)
    end

    # Event handler called at the beginning of the shape handle dragging process.
    # The function can be overridden if necessary.
	  # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_begin_handle(handle)
      # inform all selected shapes about begin of the handle dragging
      if get_parent_canvas
        lst_shapes = get_parent_canvas.get_selected_shapes
        lst_shapes.each { |shape| shape.on_begin_handle(handle) }
      end
    end

	  # Event handler called during dragging of the shape handle.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework (by the shape canvas).
	  # @param [Shape::Handle] handle Reference to dragged handle
    def on_handle(handle)
      super
      get_parent_canvas.invalidate_visible_rect
    end

    # Event handler called at the end of the shape handle dragging process.
    # The function can be overridden if necessary.
	  # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_end_handle(handle)
      # inform all selected shapes about end of the handle dragging
      if get_parent_canvas
        lst_shapes = get_parent_canvas.get_selected_shapes
        lst_shapes.each { |shape| shape.on_end_handle(handle) }
      end
    end

    protected

    # Event handler called during dragging of the right shape handle.
    # The function can be overridden if necessary.
	  # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_right_handle(handle)
      if get_parent_canvas && !any_width_exceeded(handle.get_delta)
        sx = (get_rect_size.x - 2*DEFAULT_ME_OFFSET + handle.get_delta.x).to_f/(get_rect_size.x - 2*DEFAULT_ME_OFFSET)
    
        lst_selection = get_parent_canvas.get_selected_shapes
    
        lst_selection.each do |shape|
          # scale main parent shape
          if !shape.is_a?(LineShape)
            shape.scale(sx, 1, children: WITHCHILDREN) if shape.has_style?(STYLE::SIZE_CHANGE)
            if shape.has_style?(STYLE::POSITION_CHANGE)
              dx = (shape.get_absolute_position.x - (get_absolute_position.x + DEFAULT_ME_OFFSET))/(get_rect_size.x - 2*DEFAULT_ME_OFFSET)*handle.get_delta.x
              shape.move_by(dx, 0)
            end
            shape.fit_to_children unless shape.has_style?(STYLE::NO_FIT_TO_CHILDREN)
          else
            if shape.contains_style(STYLE::POSITION_CHANGE)
              shape.get_control_points.each do |cpt|
                dx = (cpt.x - (get_absolute_position.x + DEFAULT_ME_OFFSET))/(get_rect_size.x - 2*DEFAULT_ME_OFFSET)*handle.get_delta.x
                cpt.x += dx
                cpt.x = cpt.x.floor
              end
            end
          end
        end
      end
    end

    # Event handler called during dragging of the left shape handle.
    # The function can be overridden if necessary.
	  # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_left_handle(handle)
      if get_parent_canvas && !any_width_exceeded(Wx::Point.new(-handle.get_delta.x, 0))
        sx = (get_rect_size.x - 2*DEFAULT_ME_OFFSET - handle.get_delta.x).to_f/(get_rect_size.x - 2*DEFAULT_ME_OFFSET)
    
        lst_selection = get_parent_canvas.get_selected_shapes
    
        lst_selection.each do |shape|
          if !shape.is_a?(LineShape)
            if shape.has_style?(STYLE::POSITION_CHANGE)
              if shape.get_parent_shape
                shape.set_relative_position(shape.get_relative_position.x*sx, shape.get_relative_position.y)
              else
                dx = handle.get_delta.x - (shape.get_absolute_position.x - (get_absolute_position.x + DEFAULT_ME_OFFSET))/(get_rect_size.x - 2*DEFAULT_ME_OFFSET)*handle.get_delta.x
                shape.move_by(dx, 0)
              end
            end
            shape.scale(sx, 1, children: WITHCHILDREN) if shape.has_style?(STYLE::SIZE_CHANGE)
            shape.fit_to_children unless shape.has_style?(STYLE::NO_FIT_TO_CHILDREN)
          else
            if shape.has_style?(STYLE::POSITION_CHANGE)
              shape.get_control_points.each do |cpt|
                dx = handle.get_delta.x - (cpt.x - (get_absolute_position.x + DEFAULT_ME_OFFSET))/(get_rect_size.x - 2*DEFAULT_ME_OFFSET)*handle.get_delta.x
                cpt.x += dx
                cpt.x = cpt.x.floor
              end
            end
          end
        end
      end
    end

    # Event handler called during dragging of the top shape handle.
    # The function can be overridden if necessary.
	  # @param [Shape::Handle] handle Reference to dragged shape handle
    def on_top_handle(handle)
      if get_parent_canvas && !any_height_exceeded(Wx::Point.new(0, -handle.get_delta.y))
        sy = (get_rect_size.y - 2*DEFAULT_ME_OFFSET - handle.get_delta.y).to_f/(get_rect_size.y - 2*DEFAULT_ME_OFFSET)
    
        lst_selection = get_parent_canvas.get_selected_shapes
    
        lst_selection.each do |shape|
          if !shape.is_a?(LineShape)
            if shape.has_style?(STYLE::POSITION_CHANGE)
              if shape.get_parent_shape
                shape.set_relative_position(shape.get_relative_position.x, shape.get_relative_position.y*sy)
              else
                dy = handle.get_delta.y - (shape.get_absolute_position.y - (get_absolute_position.y + DEFAULT_ME_OFFSET))/(get_rect_size.y - 2*DEFAULT_ME_OFFSET)*handle.get_delta.y
                shape.move_by(0, dy)
              end
            end
            shape.scale(1, sy, children: WITHCHILDREN) if shape.has_style?(STYLE::SIZE_CHANGE)
            shape.fit_to_children unless shape.has_style?(STYLE::NO_FIT_TO_CHILDREN)
          else
            if shape.has_style?(STYLE::POSITION_CHANGE)
              shape.get_control_points.each do |cpt|
                dy = handle.get_delta.y - (cpt.y - (get_absolute_position.y + DEFAULT_ME_OFFSET))/(get_rect_size.y - 2*DEFAULT_ME_OFFSET)*handle.get_delta.y
                cpt.y += dy
                cpt.y = cpt.y.floor
              end
            end
          end
        end
      end
    end

    # Event handler called during dragging of the bottom shape handle.
    # The function can be overridden if necessary.
	  # @param handle Reference to dragged shape handle
    def on_bottom_handle(handle)
      if get_parent_canvas && !any_height_exceeded(handle.get_delta)
        sy = (get_rect_size.y - 2*DEFAULT_ME_OFFSET + handle.get_delta.y).to_f/(get_rect_size.y - 2*DEFAULT_ME_OFFSET)

        lst_selection = get_parent_canvas.get_selected_shapes
    
        lst_selection.each do |shape|
          if !shape.is_a?(LineShape)
            shape.scale(1, sy, children: WITHCHILDREN) if shape.has_style?(STYLE::SIZE_CHANGE)
            if shape.has_style?(STYLE::POSITION_CHANGE)
              dy = (shape.get_absolute_position.y - (get_absolute_position.y + DEFAULT_ME_OFFSET))/(get_rect_size.y - 2*DEFAULT_ME_OFFSET)*handle.get_delta.y
              shape.move_by(0, dy)
            end
            shape.fit_to_children unless shape.has_style?(STYLE::NO_FIT_TO_CHILDREN)
          else
            if shape.has_style?(STYLE::POSITION_CHANGE)
              shape.get_control_points.each do |cpt|
                dy = (cpt.y - (get_absolute_position.y + DEFAULT_ME_OFFSET))/(get_rect_size.y - 2*DEFAULT_ME_OFFSET)*handle.get_delta.y
                cpt.y += dy
                cpt.y = cpt.y.floor
              end
            end
          end
        end
      end
    end

    private

    # Auxiliary function.
    # @param [Wx::Point] delta
    # @return [Boolean]
    def any_width_exceeded(delta)
      if get_parent_canvas
        lst_selection = get_parent_canvas.get_selected_shapes
        # determine whether any shape in the selection exceeds its bounds
        lst_selection.each do |shape|
          return true if !shape.is_a?(LineShape) && (shape.get_bounding_box.width + delta.x) < 1
        end
        return false
      end
      true
    end

    # Auxiliary function.
    # @param [Wx::Point] delta
    # @return [Boolean]
    def any_height_exceeded(delta)
      if get_parent_canvas
        lst_selection = get_parent_canvas.get_selected_shapes
        # determine whether any shape in the selection exceeds its bounds
        lst_selection.each do |shape|
          return true if !shape.is_a?(LineShape) && (shape.get_bounding_box.height + delta.y) < 1
        end
        return false
      end
      true
    end

  end

end
