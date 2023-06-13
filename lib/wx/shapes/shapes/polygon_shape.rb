# Wx::SF::PolygonShape - polygon shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'

module Wx::SF

  # Class extends the Wx::SF::RectShape and encapsulates general polygon shape
  # defined by a set of its vertices. The class can be used as it is or as a base class
  # for shapes with more complex form and functionality.
  # @see Wx::SF::DiamondShape
  class PolygonShape < RectShape

    # default values
    module DEFAULT
      # Default value of Wx::SF::PolygonShape @connect_to_vertex data member.
      VERTEXCONNECTIONS = true
    end

    property :connect_to_vertex, :vertices

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, diagram)
    #   User constructor.
    #   @param [Array<Wx::RealPoint>] pts Array of the polygon vertices
    #   @param [Wx::RealPoint] pos Initial position
    #   @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(*args)
      @connect_to_vertex = DEFAULT::VERTEXCONNECTIONS
      @vertices = []
      if args.empty?
        super
      else
        pts, pos, diagram = args
        super(pos,Wx::RealPoint.new(1,1), diagram)
        set_vertices(pts)
      end
    end

    # Set connecting mode.
    # @param [Boolean] enable Set this parameter to true if you want to connect
    # line shapes to the polygon's vertices, otherwise the lines will be connected
    # to the nearest point of the shape's border.
    def set_connect_to_vertex(enable)
      @connect_to_vertex = enable
    end
    alias :connect_to_vertex= :set_connect_to_vertex

    # Get status of connecting mode.
    # @return [Boolean] true if the line shapes will be connected to the polygon's vertices
    def is_connected_to_vertex
      @connect_to_vertex
    end
    alias :connected_to_vertex? :is_connected_to_vertex
    alias :get_connect_to_vertex :is_connected_to_vertex

    # Set the poly vertices which define its form.
	  # @param [Array<Wx::RealPoint] pts Array of the vertices
    def set_vertices(pts)
      ::Kernel.raise ArgumentError, 'Expected an array of Wx::RealPoint' unless pts.all? { |pt| pt.is_a?(Wx::RealPoint) }
      @vertices = pts.collect { |pt| pt.dup }
      normalize_vertices
      fit_bounding_box_to_vertices
    end

    # Get the poly vertices. Serialization only.
    # @return [Array<Wx::RealPoint>]
    def get_vertices
      @vertices
    end
    private :get_vertices

    # Resize the rectangle to bound all child shapes. The function can be overridden if necessary.
    def fit_to_children
      super
      fit_vertices_to_bounding_box
    end

	  # Get intersection point of the shape border and a line leading from
    # 'start' point to 'end' point. The function can be overridden if necessary.
	  # @param [Wx::RealPoint] start Starting point of the virtual intersection line
    # @param [Wx::RealPoint] end_pt Ending point of the virtual intersection line
	  # @return [Wx::RealPoint] Intersection point
    def get_border_point(start, end_pt)
      # HINT: override it for custom actions ...
      return get_center if @vertices.empty?

      pts = get_translated_vertices
      intersection = start

      if @connect_to_vertex
        intersection = pts.shift
        min_dist = intersection.distance_to(end_pt)
        pts.each do |pt|
          tmp_min_dist = pt.distance_to(end_pt)
          if tmp_min_dist < min_dist
            min_dist = tmp_min_dist
            intersection = pt
          end
        end
    
        intersection
      else
        success = false
        pts.each_with_index do |pt, i|
          if tmp_intersection = Wx::SF::Shape.lines_intersection(pt, pts[(i+1) % pts.size], start, end_pt)
            if !success
              min_dist = intersection.distance_to(end_pt)
              intersection = tmp_intersection
            else
              tmp_min_dist = intersection.distance_to(end_pt)
              if tmp_min_dist < min_dist
                min_dist = tmp_min_dist
                intersection = tmp_intersection
              end
            end
            success = true
          end
        end

        success ? intersection : get_center
      end
    end

	  # Event handler called during dragging of the shape handle.
    # The function can be overridden if necessary.
    #
    # The function is called by the framework (by the shape canvas).
	  # @param [Shape::Handle] handle Reference to dragged handle
    def on_handle(handle)
      super
      fit_vertices_to_bounding_box
    end

    protected

    # Scale the rectangle size for this shape.
    # @param [Float] x Horizontal scale factor
    # @param [Float] y Vertical scale factor
    def scale_rectangle(x, y)
      rect_size.x *= x
      rect_size.y *= y

      fit_vertices_to_bounding_box
    end

	  # Move all vertices so the polygon's relative bounding box position
    # will be located in the origin.
    def normalize_vertices
      # move all vertices so the polygon's relative bounding box will be located in the origin
    
      minx, miny, _, _ = get_extents
    
      dx = minx*(-1)
      dy = miny*(-1)
    
      @vertices.each do |pt|
        pt.x += dx
        pt.y += dy
      end
    end

    # Scale polygon's vertices to fit into the rectangle bounding the polygon.
    def fit_vertices_to_bounding_box
      minx, miny, maxx, maxy = get_extents

      sx = rect_size.x/(maxx - minx)
      sy = rect_size.y/(maxy - miny)

      @vertices.each do |pt|
        pt.x *= sx
        pt.y *= sy
      end
    end

    # Scale the bounding rectangle to fit all polygons vertices.
    def fit_bounding_box_to_vertices
      minx, miny, maxx, maxy = get_extents

      rect_size.x = maxx - minx
      rect_size.y = maxy - miny
    end

	  # Get polygon extents.
	  # @return [Array(Float,Float,Float,Float)] Positions of the left, top, right and bottom side of polygon's bounding box
    def get_extents
      return [0.0,0.0,0.0,0.0] if @vertices.empty?

      minx = maxx = @vertices.first.x
      miny = maxy = @vertices.first.y

      @vertices.inject(nil) do |exts, pt|
        if exts
          exts[0] = pt.x if pt.x < exts[0]
          exts[1] = pt.y if pt.y < exts[1]
          exts[2] = pt.x if pt.x > exts[2]
          exts[3] = pt.y if pt.y > exts[3]
        else
          exts = [pt.x, pt.y, pt.x, pt.y]
        end
        exts
      end
    end

	  # Get absolute positions of the polygon's vertices.
	  # @return [Array<Wx::RealPoint>] pts Array of translated polygon's vertices
    def get_translated_vertices
      abs_pos = get_absolute_position
      @vertices.collect { |pt| abs_pos + pt }
    end

	  # Get absolute positions of the polygon's vertices.
    # @return [Array<Wx::Point>] pts Array of translated polygon's vertices
    def get_translated_vertice_points
      abs_pos = get_absolute_position.to_point
      @vertices.collect { |pt| abs_pos + pt.to_point }
    end

	  # Draw the polygon shape.
    # @param [Wx::DC] dc Reference to the device context where the shape will be drawn to
    def draw_polygon_shape(dc)
      pts = get_translated_vertice_points
      dc.draw_polygon(pts)
    end

	  # Draw the shape in the normal way. The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_normal(dc)
      # HINT: overload it for custom actions...

      dc.with_pen(@border) do
        dc.with_brush(@fill) do
          draw_polygon_shape(dc)
        end
      end
    end

	  # Draw the shape in the hover mode (the mouse cursor is above the shape).
    # The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_hover(dc)
      # HINT: overload it for custom actions...

      dc.with_pen(Wx::Pen.new(get_hover_colour, 1)) do
        dc.with_brush(@fill) do
          draw_polygon_shape(dc)
        end
      end
    end

	  # Draw the shape in the highlighted mode (another shape is dragged over this
    # shape and this shape will accept the dragged one if it will be dropped on it).
    # The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shape will be drawn to
    def draw_highlighted(dc)
      # HINT: overload it for custom actions...

      dc.with_pen(Wx::Pen.new(get_hover_colour, 2)) do
        dc.with_brush(@fill) do
          draw_polygon_shape(dc)
        end
      end
    end

	  # Draw shadow under the shape. The function can be overridden if necessary.
	  # @param [Wx::DC] dc Reference to device context where the shadow will be drawn to
    def draw_shadow(dc)
      # HINT: overload it for custom actions...

      if @fill.get_style != Wx::BrushStyle::TRANSPARENT
        dc.with_pen(Wx::TRANSPARENT_PEN) do
          dc.with_brush(get_parent_canvas.get_shadow_fill) do
            offset = get_parent_canvas.get_shadow_offset

            move_by(offset)
            draw_polygon_shape(dc)
            move_by(-offset.x, -offset.y)
          end
        end
      end
    end

    # Deserialize attributes and recalculate rectangle size afterwards.
    # @param [Hash] data
    # @return [self]
    def from_serialized(data)
      super
      normalize_vertices
      fit_vertices_to_bounding_box
      self
    end

  end

end
