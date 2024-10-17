# Wx::SF::FilledArrow - closed line drawn arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/line_arrow'

module Wx::SF

  # Class extends the Wx::LineArrow class and encapsulates
  # enclosed and filled arrow shapes.
  class FilledArrow < LineArrow

    module DEFAULT
      class << self
        def fill; Wx::Brush.new(Wx::WHITE); end
      end
    end

    property :fill

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super
      @fill = DEFAULT.fill
    end

    # Get arrow fill brush
    # @return [Wx::Brush]
    def get_fill
      @fill
    end
    alias :fill :get_fill

    # Set arrow fill brush
    # @param [Wx::Brush] brush
    def set_fill(brush)
      @fill = brush
    end
    alias :fill= :set_fill

  end

end
