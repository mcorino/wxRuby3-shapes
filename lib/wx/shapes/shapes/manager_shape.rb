# Wx::SF::ContainerShape - container shape mixin
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  # Mixin for container shape classes that control there child shape size/position/alignment.
  module ManagerShape

    # Returns true if the shape manages (size/position/alignment) of it's child shapes.
    # @return [Boolean] true
    def is_manager
      true
    end
    alias :manager? :is_manager

    # Update the shape's position in order to its alignment
    def do_alignment
      super

      # do alignment of shape's children
      do_children_layout
    end

    protected

    def do_children_layout
      raise NotImplementedError, 'Manager shapes need override'
    end

    # Move and resize given shape so it will fit the given bounding rectangle.
    #
    # The shape is aligned inside the given bounding rectangle in accordance to the shape's
    # valign and halign flags.
    # @param [Shape] shape modified shape
    # @param [Wx::Rect] rct Bounding rectangle
    # @see Shape#set_v_align
    # @see Shape#set_h_align
    def fit_shape_to_rect(shape, rct)
      shape_bb = shape.get_bounding_box
      prev_pos = shape.get_relative_position

      # do vertical alignment
      case shape.get_v_align
      when Shape::VALIGN::TOP
        shape.set_relative_position(prev_pos.x, rct.top + shape.get_v_border)
      when Shape::VALIGN::MIDDLE
        shape.set_relative_position(prev_pos.x, rct.top + (rct.height/2 - shape_bb.height/2))
      when Shape::VALIGN::BOTTOM
        shape.set_relative_position(prev_pos.x, rct.bottom - shape_bb.height - shape.get_v_border)
      when Shape::VALIGN::EXPAND
        shape.set_relative_position(prev_pos.x, rct.top + shape.get_v_border)
        shape.scale(1.0, (rct.height - 2*shape.get_v_border).to_f/shape_bb.height)
      else
        shape.set_relative_position(prev_pos.x, rct.top)
      end

      prev_pos = shape.get_relative_position

      # do horizontal alignment
      case shape.get_h_align
      when Shape::HALIGN::LEFT
        shape.set_relative_position(rct.left + shape.get_h_border, prev_pos.y)
      when Shape::HALIGN::CENTER
        shape.set_relative_position(rct.left + (rct.width/2 - shape_bb.width/2), prev_pos.y)
      when Shape::HALIGN::RIGHT
        shape.set_relative_position(rct.right - shape_bb.width - shape.get_h_border, prev_pos.y)
      when Shape::HALIGN::EXPAND
        shape.set_relative_position(rct.left + shape.get_h_border, prev_pos.y)
        shape.scale((rct.width - 2*shape.get_h_border).to_f/shape_bb.width, 1.0)
      else
        shape.set_relative_position(rct.left, prev_pos.y)
      end
    end

  end

end
