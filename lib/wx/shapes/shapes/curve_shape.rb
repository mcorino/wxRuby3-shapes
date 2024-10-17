# Wx::SF::CurveShape - curved line shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/line_shape'

module Wx::SF

  # Interpolation line shape. The class extends LineShape class and allows
  # user to create curved connection line.
  class CurveShape < LineShape

    # @overload initialize(src = DEFAULT::POINT, trg = DEFAULT::POINT, path: nil, manager: nil)
    #   Constructor.
    #   @param [Wx::RealPoint,Wx::Point] src starting line point
    #   @param [Wx::RealPoint,Wx::Point] trg end line point
    #   @param [Array<Wx::RealPoint>,nil] path List of the line control points (can be empty or nil)
    #   @param [Diagram] diagram containing diagram
    # @overload initialize(src, trg, path: nil, manager: nil)
    #   Constructor for connecting two shapes.
    #   @param [Shape] src source shape
    #   @param [Shape] trg target shape
    #   @param [Array<Wx::RealPoint>,nil] path List of the line control points (can be empty or nil)
    #   @param [Diagram] diagram containing diagram
    def initialize(*args, **kwargs)
      super
    end

    # Get line's bounding box. The function can be overridden if necessary.
    # @return [Wx::Rect] Bounding rectangle
    def get_bounding_box
      super.inflate(35, 35)
    end

    # Get a line point laying on the given line segment and shifted
    # from the beginning of the segment by given offset.
    # @param [Integer] segment Zero-based index of the line segment
    # @param [Float] offset Real value in the range from 0 to 1 which determines
    # the line-point offset inside the line segment
    # @return [Wx::RealPoint] Line point
    def get_point(segment, offset)
      if segment <= @lst_points.size
        a,b,c,d = get_segment_quaternion(segment)
        coord_catmul_rom_kubika(a, b, c, d, offset)
      else
        Wx::RealPoint.new
      end
    end

    protected

    # Internal function used for drawing of completed line shape.
    # @param [Wx::DC] dc Reference of the device context where the shape will be drawn to
    def draw_complete_line(dc)
      case @mode
      when LINEMODE::READY
        # draw line segments
        b = c = nil
        if !@lst_points.empty?
          (0..@lst_points.size).each do |i|
            a,b,c,d = get_segment_quaternion(i)
            if i == 0 && @src_arrow
              src, trg = get_line_segment(i)
              src = @src_arrow.draw(trg, src, dc)
              a = b = src.to_real
            end
            if i == @lst_points.size && @trg_arrow
              src, trg = get_line_segment(i)
              trg = @trg_arrow.draw(src, trg, dc)
              c = d = trg.to_real
            end
            catmul_rom_kubika(a, b, c, d, dc, at_end: i == @lst_points.size)
          end
        else
          src, trg = get_direct_line.collect(&:to_point)
          src = @src_arrow.draw(trg, src, dc) if @src_arrow
          trg = @trg_arrow.draw(src, trg, dc) if @trg_arrow
          dc.draw_line(src, trg)
        end

      when LINEMODE::UNDERCONSTRUCTION
        # draw basic line parts
        c = nil
        unless @lst_points.empty?
          @lst_points.size.times do |i|
            a,b,c,d = get_segment_quaternion(i)
            catmul_rom_kubika(a, b, c, d, dc)
          end
        end
        # draw unfinished line segment if any (for interactive line creation)
        dc.with_pen(Wx::Pen.new(Wx::BLACK, 1, Wx::PenStyle::PENSTYLE_DOT)) do
          if @lst_points.size > 1
            dc.draw_line(c.to_point, @unfinished_point)
          elsif @src_shape
            # draw unfinished line segment if any (for interactive line creation)
            dc.with_pen(Wx::Pen.new(Wx::BLACK, 1, Wx::PenStyle::PENSTYLE_DOT)) do
              if @src_shape.get_connection_points.empty?
                dc.draw_line((@src_shape.get_border_point(@src_shape.get_center, @unfinished_point.to_real)).to_point,
                             @unfinished_point)
              else
                dc.draw_line(get_mod_src_point.to_point, @unfinished_point)
              end
            end
          end
        end

      when LINEMODE::SRCCHANGE
        # draw basic line parts
        c = nil
        @lst_points.size.times do |i|
          a,b,c,d = get_segment_quaternion(i+1)
          catmul_rom_kubika(a, b, c, d, dc)
        end
        # draw linesegment being updated
        dc.with_pen(Wx::Pen.new(Wx::BLACK, 1, Wx::PenStyle::PENSTYLE_DOT)) do
          if !@lst_points.empty?
            _,_,c,_ = get_segment_quaternion(0)
          else
            _,c = get_direct_line
          end
          dc.draw_line(@unfinished_point, c.to_point)
        end

      when LINEMODE::TRGCHANGE
        # draw basic line parts
        c = nil
        if !@lst_points.empty?
          @lst_points.size.times do |i|
            a,b,c,d = get_segment_quaternion(i)
            catmul_rom_kubika(a, b, c, d, dc)
          end
        else
          c = get_src_point
        end
        # draw linesegment being updated
        dc.with_pen(Wx::Pen.new(Wx::BLACK, 1, Wx::PenStyle::PENSTYLE_DOT)) do
          dc.draw_line(@unfinished_point, c.to_point)
        end
      end
    end

    private

	  # Auxiliary drawing function.
    # @param [Integer] segment
    # @return [Array(Wx::RealPoint,Wx::RealPoint,Wx::RealPoint,Wx::RealPoint)]
    def get_segment_quaternion(segment)
      quart = [nil,nil,nil,nil]
      index = 2 - segment

      quart[index - 1] = get_src_point if (index - 1) >= 0
      quart[index - 2] = get_mod_src_point if (index - 2) >= 0
      
      if index >= 0
        pt = @lst_points.at(ix_pt = 0)
      else
        pt = @lst_points.at(ix_pt = index.abs)
        index = 0
      end
         
      while index < 4
        if pt
          quart[index] = pt
          ix_pt += 1
          pt = @lst_points.at(ix_pt)
        else
          if index == 2
            quart[2] = get_trg_point
          elsif index == 3
            if @mode == LINEMODE::UNDERCONSTRUCTION
              quart[3] = @unfinished_point.to_real
            elsif @trg_shape
              quart[3] = get_mod_trg_point
            end
          end
        end
        index += 1
      end

      quart
    end

	  # Auxiliary drawing function.
    # @param [Wx::RealPoint] a
    # @param [Wx::RealPoint] b
    # @param [Wx::RealPoint] c
    # @param [Wx::RealPoint] d
    # @param [Wx::DC] dc
    def catmul_rom_kubika(a, b, c, d, dc, at_end: false)
      # the beginning of the curve is in the B point
      point0 = b

      optim_steps = b.distance_to(c).to_f / 10
      optim_steps = 10 if optim_steps < 10
    
      # draw the curve
      t = 0.0
      while t <= (1 + (1.0 / optim_steps))
        point1 = coord_catmul_rom_kubika(a,b,c,d,t)
        # make sure not to overshoot at the target/arrow connection point
        point1 = c if at_end && point0.distance_to(point1) > point0.distance_to(c)
        dc.draw_line(point0.x.to_i, point0.y.to_i, point1.x.to_i, point1.y.to_i)
        point0 = point1
        t += 1.0 / (optim_steps-1)
      end
      point1 = coord_catmul_rom_kubika(a,b,c,d,1)
      # make sure not to overshoot at the target/arrow connection point
      point1 = c if at_end && point0.distance_to(point1) > point0.distance_to(c)
      dc.draw_line(point0.x.to_i, point0.y.to_i, point1.x.to_i, point1.y.to_i)
    end

    # Auxiliary drawing function.
    # @param [Wx::RealPoint] p1
    # @param [Wx::RealPoint] p2
    # @param [Wx::RealPoint] p3
    # @param [Wx::RealPoint] p4
    # @param [Float] t
    # @return [Wx::RealPoint]
    def coord_catmul_rom_kubika(p1, p2, p3, p4, t)
      # auxiliary variables
      pom1 = t - 1
      pom2 = t * t

      # used polynomials
      c1 = (-pom2*t + 2*pom2 - t)  / 2
      c2 = (3*pom2*t - 5*pom2 + 2) / 2
      c3 = (-3*pom2*t + 4*pom2 + t) / 2
      c4 = pom1*pom2 / 2

      # calculation of curve point for t = <0,1>
      x = c1*p1.x + c2*p2.x + c3*p3.x + c4*p4.x
      y = c1*p1.y + c2*p2.y + c3*p3.y + c4*p4.y

      Wx::RealPoint.new(x,y)
    end
    
  end

end
