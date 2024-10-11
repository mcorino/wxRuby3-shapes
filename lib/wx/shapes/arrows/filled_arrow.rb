# Wx::SF::FilledArrow - closed line drawn arrow class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/arrows/line_arrow'

module Wx::SF

  # Class extends the Wx::LineArrow class and encapsulates
  # enclosed and filled arrow shapes.
  class FilledArrow < LineArrow

    property :arrow_fill

    # Constructor
    # @param [Wx::SF::Shape] parent parent shape
    def initialize(parent=nil)
      super
      @fill = DEFAULT.fill
    end

    # Get arrow fill brush
    # @return [Wx::Brush]
    def get_arrow_fill
      @fill
    end
    alias :arrow_fill :get_arrow_fill

    # Set arrow fill brush
    # @param [Wx::Brush] brush
    def set_arrow_fill(brush)
      @fill = brush
    end
    alias :arrow_fill= :set_arrow_fill

  end

end
