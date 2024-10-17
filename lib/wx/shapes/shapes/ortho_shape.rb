# Wx::SF::OrthoLineShape - orthogonal line shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/line_shape'

module Wx::SF

  # Orthogonal line shape. The class extends LineShape class and allows
  # user to create connection line orthogonal to base axis.
  class OrthoLineShape < LineShape

    SEGMENTCPS = ::Struct.new(:src, :trg)

    # Constructor
    # @param [Shape] src source shape
    # @param [Shape] trg target shape
    # @param [Array<Wx::RealPoint>] path List of the line control points (can be empty)
    # @param [Diagram] diagram containing diagram
    def initialize(src = nil, trg = nil, path: nil, diagram: nil)
      super
    end

    protected

    # Internal function used for drawing of completed line shape.
    # @param [Wx::DC] dc Reference of the device context where the shape will be drawn to
    def draw_complete_line(dc)
      return unless @diagram
  
      src = trg = cp_src = cp_trg = nil
    
      if @src_shape
        cp_src = @src_shape.get_nearest_connection_point(get_mod_src_point)
      end
      if @trg_shape
        cp_trg = @trg_shape.get_nearest_connection_point(get_mod_trg_point)
      end
  
      case @mode
      when LINEMODE::READY
        # draw basic line parts
        n = line_segment_count-1
        (0..n).each do |i|
          src, trg = get_line_segment(i)
          # at starting (src) segment draw src arrow and get updated arrow connection point
          if i == 0 && @src_arrow
            asrc, atrg = get_first_subsegment(src, trg, get_used_connection_points(cp_src, cp_trg, 0))
            src = @src_arrow.draw(atrg, asrc, dc)
            cp_src = nil
          end
          # at end (tgt) segment draw tgt arrow and get updated connection point
          if i == n && @trg_arrow
            asrc, atrg = get_last_subsegment(src, trg, get_used_connection_points(cp_src, cp_trg, @lst_points.size))
            trg = @trg_arrow.draw(asrc, atrg, dc)
            cp_trg = nil
          end
          draw_line_segment(dc, src, trg, get_used_connection_points(cp_src, cp_trg, i))
        end

      when LINEMODE::UNDERCONSTRUCTION
        # draw basic line parts
        @lst_points.size.times do |i|
          src, trg = get_line_segment(i)
          draw_line_segment(dc, src, trg, get_used_connection_points(cp_src, cp_trg, i))
        end
  
        # draw unfinished line segment if any (for interactive line creation)
        dc.with_pen(Wx::Pen.new(Wx::BLACK, 1, Wx::PenStyle::PENSTYLE_DOT)) do
          if @lst_points.size>1
            draw_line_segment(dc, trg, @unfinished_point.to_real, get_used_connection_points(cp_src, cp_trg, @lst_points.size))
          else
            if @src_shape
              if @src_shape.get_connection_points.empty?
                draw_line_segment(dc,
                                  @src_shape.get_border_point(@src_shape.get_center, @unfinished_point.to_real),
                                  @unfinished_point.to_real,
                                  get_used_connection_points(cp_src, cp_trg, 0))
              else
                draw_line_segment(dc,
                                  get_mod_src_point,
                                  @unfinished_point.to_real,
                                  get_used_connection_points(cp_src, cp_trg, 0))
              end
            end
          end
        end

      when LINEMODE::SRCCHANGE
        # draw basic line parts
        @lst_points.size.times do |i|
          src, trg = get_line_segment(i+1)
          draw_line_segment(dc, src, trg, get_used_connection_points(cp_src, cp_trg, i+1))
        end
        # draw linesegment being updated
        src, trg = get_line_segment(0)
        dc.with_pen(Wx::Pen.new(Wx::BLACK, 1, Wx::PenStyle::PENSTYLE_DOT)) do
          draw_line_segment(dc,
                            @unfinished_point.to_real,
                            trg,
                            get_used_connection_points(cp_src, cp_trg, 0))
        end

      when LINEMODE::TRGCHANGE
        # draw basic line parts
        if !@lst_points.empty?
          @lst_points.size.times do |i|
            src, trg = get_line_segment(i)
            draw_line_segment(dc, src, trg, get_used_connection_points(cp_src, cp_trg, i))
          end
        else
          trg = get_src_point
        end
        # draw linesegment being updated
        dc.with_pen(Wx::Pen.new(Wx::BLACK, 1, Wx::PenStyle::PENSTYLE_DOT)) do
          draw_line_segment(dc,
                            trg,
                            @unfinished_point.to_real,
                            get_used_connection_points(cp_src, cp_trg, @lst_points.size))
        end

      end
    end

    # Get index of the line segment intersecting the given point.
	  # @param [Wx::Point] pos Examined point
	  # @return Zero-based index of line segment located under the given point
    def get_hit_linesegment(pos)
      return -1 unless get_bounding_box.inflate!(5, 5).contains?(pos)

      cp_src = nil
      cp_trg = nil

      if @src_shape
        cp_src = @src_shape.get_nearest_connection_point(get_mod_src_point)
      end
      if @trg_shape
        cp_trg = @trg_shape.get_nearest_connection_point(get_mod_trg_point)
      end

      # Get all polyline segments
      line_segment_count.times do |i|
        pt_src, pt_trg = get_line_segment(i)

        # test first subsegment
        pt_s_src, pt_s_trg = get_first_subsegment( pt_src, pt_trg, get_used_connection_points(cp_src, cp_trg, i))
        rct_bb = Wx::Rect.new(pt_s_src.to_point, pt_s_trg.to_point)
        rct_bb.inflate!(5)

        return i if rct_bb.contains?(pos)

        # test middle subsegment
        pt_s_src, pt_s_trg = get_middle_subsegment(pt_src, pt_trg, get_used_connection_points(cp_src, cp_trg, i))
        rct_bb = Wx::Rect.new(pt_s_src.to_point, pt_s_trg.to_point)
        rct_bb.inflate!(5)

        return i if rct_bb.contains?(pos)

        # test last subsegment
        pt_s_src, pt_s_trg = get_last_subsegment( pt_src, pt_trg, get_used_connection_points(cp_src, cp_trg, i))
        rct_bb = Wx::Rect.new(pt_s_src.to_point, pt_s_trg.to_point)
        rct_bb.inflate!(5)

        return i if rct_bb.contains?(pos)
      end

      -1
    end

	  # Draw one orthogonal line segment.
	  # @param [Wx::DC] dc Device context
	  # @param [Wx::RealPoint] src Starting point of the ortho line segment
	  # @param [Wx::RealPoint] trg Ending point of the ortho line segment
	  # @param [SEGMENTCPS] cps Connection points used by the line segment
    def draw_line_segment(dc, src, trg, cps)
      direction = 0.0
      src_pt = src.to_point
      trg_pt = trg.to_point

      if (trg.x == src.x) || (trg.y == src.y)
        dc.draw_line(src_pt, trg_pt)
        return
      else
        direction = get_segment_direction(src, trg, cps)
      end
      
      if is_two_segment(cps)
        if direction < 1.0
          dc.draw_line(src_pt.x, src_pt.y, trg_pt.x, src_pt.y)
          dc.draw_line(trg_pt.x, src_pt.y, trg_pt.x, trg_pt.y)
        else
          dc.draw_line(src_pt.x, src_pt.y, src_pt.x, trg_pt.y)
          dc.draw_line(src_pt.x, trg_pt.y, trg_pt.x, trg_pt.y)
        end
      else
        pt_center = Wx::Point.new(((src.x + trg.x)/2).to_i, ((src.y + trg.y)/2).to_i)
        if direction < 1.0
          dc.draw_line(src_pt.x, src_pt.y, pt_center.x, src_pt.y)
          dc.draw_line(pt_center.x, src_pt.y, pt_center.x, trg_pt.y)
          dc.draw_line(pt_center.x, trg_pt.y, trg_pt.x, trg_pt.y)
        else
          dc.draw_line(src_pt.x, src_pt.y, src_pt.x, pt_center.y)
          dc.draw_line(src_pt.x, pt_center.y, trg_pt.x, pt_center.y)
          dc.draw_line(trg_pt.x, pt_center.y, trg_pt.x, trg_pt.y)
        end
      end
    end

	  # Get first part of orthogonal line segment.
    # @param [Wx::RealPoint] src Starting point of the ortho line segment
    # @param [Wx::RealPoint] trg Ending point of the ortho line segment
	  # @param [SEGMENTCPS] cps Connection points used by the line segment
    # @return [Array(Wx::RealPoint, Wx::RealPoint)] starting and ending point of the first part of ortho line segment
    def get_first_subsegment(src, trg, cps)
      direction = get_segment_direction(src, trg, cps)
      
      if is_two_segment(cps)
        if direction < 1.0
          subsrc = src
          subtrg = Wx::RealPoint.new(trg.x, src.y)
        else
          subsrc = src
          subtrg = Wx::RealPoint.new(src.x, trg.y)
        end
      else
        pt_center = Wx::RealPoint.new((src.x + trg.x)/2, (src.y + trg.y)/2)
        if direction < 1.0
          subsrc = src
          subtrg = Wx::RealPoint.new(pt_center.x, src.y)
        else
          subsrc = src
          subtrg = Wx::RealPoint.new(src.x, pt_center.y)
        end
      end
      [subsrc, subtrg]
    end

	  # Get middle part of orthogonal line segment.
    # @param [Wx::RealPoint] src Starting point of the ortho line segment
    # @param [Wx::RealPoint] trg Ending point of the ortho line segment
    # @param [SEGMENTCPS] cps Connection points used by the line segment
    # @return [Array(Wx::RealPoint, Wx::RealPoint)] starting and ending point of the second part of ortho line segment
    def get_middle_subsegment(src, trg, cps)
      direction = get_segment_direction(src, trg, cps)
      
      if is_two_segment(cps)
        if direction < 1.0
          subsrc = src
          subtrg = Wx::RealPoint.new(trg.x, src.y)
        else
          subsrc = src
          subtrg = Wx::RealPoint.new(src.x, trg.y)
        end
      else
        pt_center = Wx::RealPoint.new((src.x + trg.x)/2, (src.y + trg.y)/2)
        if direction < 1.0
          subsrc = Wx::RealPoint.new(pt_center.x, src.y)
          subtrg = Wx::RealPoint.new(pt_center.x, trg.y)
        else
          subsrc = Wx::RealPoint.new(src.x, pt_center.y)
          subtrg = Wx::RealPoint.new(trg.x, pt_center.y)
        end
      end
      [subsrc, subtrg]
    end

	  # Get last part of orthogonal line segment.
    # @param [Wx::RealPoint] src Starting point of the ortho line segment
    # @param [Wx::RealPoint] trg Ending point of the ortho line segment
    # @param [SEGMENTCPS] cps Connection points used by the line segment
    # @return [Array(Wx::RealPoint, Wx::RealPoint)] starting and ending point of the third part of ortho line segment
    def get_last_subsegment(src, trg, cps)
      direction = get_segment_direction(src, trg, cps)
    
      if is_two_segment(cps)
        if direction < 1.0
          subsrc = Wx::RealPoint.new(trg.x, src.y)
        else
          subsrc = Wx::RealPoint.new(src.x, trg.y)
        end
      else
        pt_center = Wx::RealPoint.new((src.x + trg.x)/2, (src.y + trg.y)/2)
        if direction < 1.0
          subsrc = Wx::RealPoint.new(pt_center.x, trg.y)
        else
          subsrc = Wx::RealPoint.new(trg.x, pt_center.y)
        end
      end
      [subsrc, trg]
    end

	  # Get direction of the line segment.
    # @param [Wx::RealPoint] src Starting point of the ortho line segment
    # @param [Wx::RealPoint] trg Ending point of the ortho line segment
    # @param [SEGMENTCPS] cps Connection points used by the line segment
	  # @return [Float] Direction number
    def get_segment_direction(src, trg, cps)
      direction = 0

      if trg.x == src.x
        direction = 1
      else
        direction =  (trg.y - src.y).abs / (trg.x - src.x).abs

        cp = nil
        if cps.src && !cps.trg
          cp = cps.src
        elsif !cps.src && cps.trg
          cp = cps.trg
        elsif cps.src && cps.trg
          cp = cps.src
        end

        if cp
          case cp.get_ortho_direction
          when ConnectionPoint::CPORTHODIR::VERTICAL
            direction = 1.0
          when ConnectionPoint::CPORTHODIR::HORIZONTAL
            direction = 0.0
          end
        end
      end

      direction
    end

	  # Determine which available connection points are used by given line segment.
	  # @param [Wx::SF::ConnectionPoint] src Potential source connection point (can be nil)
	  # @param [Wx::SF::ConnectionPoint] trg Potential target connection point (can be nil)
	  # @param [Integer] i Index of the line segment
	  # @return [SEGMENTCPS] Structure containing used connection points
    def get_used_connection_points(src, trg, i)
      if @lst_points.empty?
        SEGMENTCPS.new(src, trg)
      elsif i == 0
        SEGMENTCPS.new(src, nil)
      elsif i == @lst_points.size
        SEGMENTCPS.new(nil, trg)
      else
        SEGMENTCPS.new(nil, nil)
      end
    end

	  # Determine whether a line using give connection point should be drawn as two-segmented.
	  # @param [SEGMENTCPS] cps Used connection points
	  # @return [Boolean] true if the line should be just two-segmented
    def is_two_segment(cps)
      cps.src && cps.trg && (cps.src.get_ortho_direction != cps.trg.get_ortho_direction)
    end

  end

end
