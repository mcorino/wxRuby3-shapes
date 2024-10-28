# Wx::SF::ConnectionPoint - shape connection point class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/serializable'

module Wx::SF

  class ConnectionPoint

    include FIRM::Serializable

    property :type
    property :ortho_direction
    property :relative_position

    RADIUS = 3

    # Connection point type
    class CPTYPE < Wx::Enum
      UNDEF = self.new(0)
      TOPLEFT = self.new(1)
      TOPMIDDLE = self.new(2)
      TOPRIGHT = self.new(3)
      CENTERLEFT = self.new(4)
      CENTERMIDDLE = self.new(5)
      CENTERRIGHT = self.new(6)
      BOTTOMLEFT = self.new(7)
      BOTTOMMIDDLE = self.new(8)
      BOTTOMRIGHT = self.new(9)
      CUSTOM = self.new(10)
    end

    # Direction of orthogonal connection
    class CPORTHODIR < Wx::Enum
      UNDEF = self.new(1)
      HORIZONTAL = self.new(2)
      VERTICAL = self.new(3)
    end
    
    module DEFAULT
      # Default value of Wx::SF::ConnectionPoint @rel_position data member
      RELPOS = Wx::RealPoint.new(0, 0)
      # Default value of Wx::SF::ConnectionPoint @ortho_dir data member
      ORTHODIR = CPORTHODIR::UNDEF
    end

    # Constructor
    # @overload initialize()
    #   default ctor for deserialize
    # @overload initialize(parent, pos, id=nil)
    #   @param [Wx::SF::Shape] parent parent shape
    #   @param [Wx::RealPoint,Array(Float, Float)] pos relative position in percentages
    #   @param [Integer] id point id
    # @overload initialize(parent, type)
    #   @param [Wx::SF::Shape] parent parent shape
    #   @param [Wx::SF::ConnectionPoint::CPTYPE] type connection point type
    def initialize(*args)
      @parent_shape, type_or_pos, id = *args
      if type_or_pos # allow parent to be nil (mainly for testing purposes)
        if CPTYPE === type_or_pos
          @type = type_or_pos
          @rel_position = DEFAULT::RELPOS
          @id = nil
        elsif Wx::RealPoint === type_or_pos || Array === type_or_pos
          @type = CPTYPE::CUSTOM
          @rel_position = Wx::RealPoint === type_or_pos ? type_or_pos : Wx::RealPoint.new(*type_or_pos)
          @id = id
        else
          ::Kernel.raise ArgumentError, 'Invalid arguments'
        end
        @ortho_dir = DEFAULT::ORTHODIR
        @mouse_over = false
      end
    end

    attr_accessor :id

    #  Get connection point type.
	  # @return [CPTYPE] Connection point type
    def get_type
      @type
    end
    alias :type :get_type

    # Set connection point type.
    # @param [CPTYPE] type
    def set_type(type)
      @type = type
    end
    alias :type= :set_type

    #  Set direction of orthogonal line's connection.
	  # @param [CPORTHODIR] dir Required direction
	  # @see CPORTHODIR
    def set_ortho_direction(dir)
      @ortho_dir = dir
    end
    alias :ortho_direction= :set_ortho_direction

    #  Get direction of orthogonal line's connection.
	  # @return [CPORTHODIR] Current direction
	  # @see CPORTHODIR
    def get_ortho_direction
      @ortho_dir
    end
    alias :ortho_direction :get_ortho_direction

    # Set parent shape.
	  # @param [Wx::SF::Shape] parent parent shape
    def set_parent_shape(parent)
      @parent_shape = parent
    end
    alias :parent_shape= :set_parent_shape

    # Get parent shape.
	  # @return [Wx::SF::Shape] parent shape
    def get_parent_shape
      @parent_shape
    end
    alias :parent_shape :get_parent_shape

    #  Set relative position of custom connection point.
    #  @param [Wx::RealPoint,Array(Float, Float)] pos Relative position in percentages
    def set_relative_position(pos)
      @rel_position = Wx::RealPoint === pos ? pos : Wx::RealPoint.new(*pos)
    end
    alias :relative_position= :set_relative_position

    # Get relative position of custom connection point.
	  # @return [Wx::RealPoint] Relative position in percentages
    def get_relative_position
      @rel_position
    end
    alias :relative_position :get_relative_position

    # Get absolute position of the connection point.
	  # @return [Wx::RealPoint] Absolute position of the connection point
    def get_connection_point
      if @parent_shape
        rctParent = @parent_shape.get_bounding_box

        case @type 
        when CPTYPE::TOPLEFT
          return rctParent.top_left.to_real

        when CPTYPE::TOPMIDDLE
          return Wx::RealPoint.new((rctParent.left + rctParent.width/2).to_f, rctParent.top.to_f)

        when CPTYPE::TOPRIGHT
          return rctParent.top_right.to_real

        when CPTYPE::CENTERLEFT
          return Wx::RealPoint.new(rctParent.left.to_f, (rctParent.top + rctParent.height/2).to_f)

        when CPTYPE::CENTERMIDDLE
          return Wx::RealPoint.new((rctParent.left + rctParent.width/2).to_f, (rctParent.top + rctParent.height/2).to_f)

        when CPTYPE::CENTERRIGHT
          return Wx::RealPoint.new(rctParent.right.to_f, (rctParent.top + rctParent.height/2).to_f)

        when CPTYPE::BOTTOMLEFT
          return rctParent.bottom_left.to_real

        when CPTYPE::BOTTOMMIDDLE
          return Wx::RealPoint.new((rctParent.left + rctParent.width/2).to_f, rctParent.bottom.to_f)

        when CPTYPE::BOTTOMRIGHT
          return rctParent.bottom_right.to_real

        when CPTYPE::CUSTOM
          return Wx::RealPoint.new(rctParent.left + rctParent.width * @rel_position.x/100, rctParent.top + rctParent.height * @rel_position.y/100)
        end
      end
      Wx::RealPoint.new
    end
    alias :connection_point :get_connection_point

    #  Find out whether given point is inside the connection point.
	  # @param [Wx::Point] pos Examined point
	  # @return [Boolean] true if the point is inside the handle, otherwise false
    def contains(pos)
      # HINT: overload it for custom actions...
      connection_point.distance_to(pos.to_real_point) < (3 * RADIUS)
    end
    alias :contains? :contains

    #  Draw connection point.
	  # @param [Wx::DC] dc Device context where the handle will be drawn
    def draw(dc)
      if @mouse_over
        draw_hover(dc)
      else
        draw_normal(dc)
      end
    end

    # Refresh (repaint) the dock point
    def refresh
      @parent_shape.refresh(DELAYED)
    end

    protected

    #  Draw the connection point in the normal way. The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)
      # HINT: overload it for custom actions...
    end

    #  Draw the connection point in the hover mode (the mouse cursor is above the shape).
    # The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)
      # HINT: overload it for custom actions...
      dc.with_pen(Wx::BLACK_PEN) do
        dc.with_brush(Wx::RED_BRUSH) do
          dc.draw_circle(connection_point.to_point, RADIUS)
        end
      end
    end

    private

    #  Event handler called when the mouse pointer is moving above shape canvas.
    # @param [Wx::Point] pos Current mouse position
    def _on_mouse_move(pos)
      if contains?(pos)
        unless @mouse_over
          @mouse_over = true
          refresh
        end
      else
        if @mouse_over
          @mouse_over = false
          refresh
        end
      end
    end
    
  end

end
