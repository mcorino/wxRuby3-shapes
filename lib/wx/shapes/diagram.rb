# Wx::SF::Diagram - diagram class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/serializable'
require 'wx/shapes/shape'
require 'wx/shapes/shape_canvas'

module Wx::SF

  INCLUDE_PARENTS = true
  WITHOUT_PARENTS = false
  INITIALIZE = true
  DONT_INITIALIZE = false

  class Diagram

    include Serializable

    property :shapes

    # Search mode flags for get_shape_at_position method
    class SEARCHMODE < Wx::Enum
      # Search for selected shapes only
      SELECTED = self.new(0)
      # Search for unselected shapes only
      UNSELECTED = self.new(1)
      # Search for both selected and unselected shapes
      BOTH = self.new(2)
    end

    def initialize(manager)
      @manager =  manager
      @shapes = []
      @shapes_index = {}
      @shape_canvas = nil
    end

    attr_accessor :manager, :shape_canvas

    def get_shapes; @shapes; end
    private :get_shapes

    def set_shapes(list)
      @shapes.replace(list)
      @shapes_index.clear
      @shapes.each { |sh| @shapes_index[sh.id] = sh }
    end
    private :set_shapes

  end

end
