# Wx::SF::SquareShape - square shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'

module Wx::SF

  class SquareShape < RectShape


    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, diagram)
    #   User constructor.
    #   @param [Wx::RealPoint] pos Initial position
    #   @param [Float] size Initial size
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)
      if args.empty?
        super
        set_rect_size(100,100)
      else
        pos, sz, diagram = args
        super(pos, Wx::RealPoint.new(sz, sz), diagram)
      end
    end

    # Set the rectangle size.
    # @overload set_rect_size(x, y)
    #   @param [Float] x Horizontal size
    #   @param [Float] y Vertical size
    # @overload set_rect_size(size)
    #   @param [Wx::RealPoint] size New size
    def set_rect_size(arg1, arg2 = nil)
      # prevent from setting unequal dimensions
      # set to largest dimension
      if arg2
        x = arg1; y = arg2
      else
        x, y = arg1.to_real_point
      end
      sz = arg1 >= arg2 ? arg1 : arg2
      super(sz, sz)
    end
    alias :rect_size= :set_rect_size

    # Get shape's center. Default implementation does nothing. The function can be overridden if necessary.
    # @return [Wx::RealPoint] Center point
    def get_center
      # Optimize
      get_absolute_position + [@rect_size.x/2, @rect_size.y/2]
    end

    protected

    # Scale the rectangle size for this shape.
    # @param [Float] x Horizontal scale factor
    # @param [Float] y Vertical scale factor
    def scale_rectangle(x, y)
      if x == 1.0
        s = y
      elsif y == 1.0
        s = x
      elsif x >= y
        s = x
	    else
        s = y
      end

		  set_rect_size(@rect_size.x * s, @rect_size.y * s)
    end

    # Handle's shape specific actions on handling handle events.
    # The function can be overridden if necessary.
    # @param [Shape::Handle] handle Reference to dragged handle
    # @see #on_handle
    def do_on_handle(handle)
      prev_size = @rect_size
  
      # perform standard operations
      case handle.type
      when Shape::Handle::TYPE::LEFTTOP, 
           Shape::Handle::TYPE::LEFT, 
           Shape::Handle::TYPE::LEFTBOTTOM
        on_left_handle(handle)
      when Shape::Handle::TYPE::RIGHTTOP, 
           Shape::Handle::TYPE::RIGHT,
           Shape::Handle::TYPE::RIGHTBOTTOM
        on_right_handle(handle)
      when Shape::Handle::TYPE::TOP
        on_top_handle(handle)
      when Shape::Handle::TYPE::BOTTOM
        on_bottom_handle(handle)
      end
    
      # calculate common size and some auxiliary values
      if (prev_size.x < @rect_size.x) || (prev_size.y < @rect_size.y)
        if @rect_size.x >= @rect_size.y
          maxsize = @rect_size.x
        else
          maxsize = @rect_size.y
        end
      else
        if @rect_size.x <= @rect_size.y 
          maxsize = @rect_size.x
        else
          maxsize = @rect_size.y
        end
      end
  
      dx = maxsize - @rect_size.x
      dy = maxsize - @rect_size.y
  
      # normalize rect sizes
      @rect_size.x = @rect_size.y = maxsize
  
      # move rect if necessary
      case handle.type
      when Shape::Handle::TYPE::LEFT
        move_by(-dx, -dy / 2)
      when Shape::Handle::TYPE::LEFTTOP
        move_by(-dx, -dy)
      when Shape::Handle::TYPE::LEFTBOTTOM
        move_by(-dx, 0)
      when Shape::Handle::TYPE::RIGHT
        move_by(0, -dy / 2)
      when Shape::Handle::TYPE::RIGHTTOP
        move_by(0, -dy)
      when Shape::Handle::TYPE::TOP
        move_by(-dx / 2, -dy)
      when Shape::Handle::TYPE::BOTTOM
        move_by(-dx / 2, 0)
      end
    end

  end

end
