# Wx::SF::ArrowBase - arrow base class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/serializable'
require 'wx/shapes/shape'

module Wx::SF

  class ArrowBase

    include FIRM::Serializable

    module DEFAULT
      class << self
        def fill; Wx::Brush.new(Wx::WHITE); end
        def border; Wx::Pen.new(Wx::BLACK); end
      end
    end

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      @parent_shape = parent
    end

	  # Set a parent of the arrow shape.
	  # @param [Wx::SF::Shape] parent parent shape
    def set_parent_shape(parent)
      @parent_shape = parent
    end
    alias :parent_shape= :set_parent_shape

	  # Get pointer to a parent shape.
	  # @return [Wx::SF::Shape] parent shape if exists, otherwise nil
    def get_parent_shape
      @parent_shape
    end
    alias :parent_shape :get_parent_shape

	  # Draw arrow shape at the end of a virtual line.
	  # @param [Wx::RealPoint] from Start of the virtual line
	  # @param [Wx::RealPoint] to End of the virtual line
	  # @param [Wx::DC] dc Device context for drawing
    def draw(from, to, dc)
      # needs to be overridden
    end

    protected

    # Rotate and move arrow's vertices in accordance of virtual line at which end the arrow will be placed.
	  # @param [Array<Wx::RealPoint>] src array of source vertices
	  # @param [Wx::RealPoint] from Start of the virtual line
	  # @param [Wx::RealPoint] to End of the virtual line
    # @param [Array<Wx::Point>] trg array where translated vertices will be stored
    # @return [Array<Wx::Point>] array with translated vertices
    def translate_arrow(src, from, to, trg = [])
      # calculate distance between line points
      from = from.to_real_point; to = to.to_real_point
      dist = from.distance_to(to)

      if dist == 0.0
        src.each do |pt|
          trg << Wx::Point.new(((pt.x-pt.y)+to.x).to_i,
                               ((pt.x+pt.y)+to.y).to_i)
        end
      else
        # calculate sin and cos of given line segment
        sina = (from.y - to.y)/dist
        cosa = (from.x - to.x)/dist

        # rotate arrow
        src.each do |pt|
          trg << Wx::Point.new(((pt.x*cosa-pt.y*sina)+to.x).to_i,
                               ((pt.x*sina+pt.y*cosa)+to.y).to_i)
        end
      end
      trg
    end

  end

end

Dir[File.join(__dir__, 'arrows', '*.rb')].each do |f|
  require "wx/shapes/arrows/#{File.basename(f, '.rb')}"
end
