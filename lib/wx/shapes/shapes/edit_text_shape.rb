# Wx::SF::EditTextShape - edit text shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/text_shape'

module Wx::SF

  class EditTextShape < TextShape

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(pos, size, diagram)
    #   User constructor.
    #   @param pos Initial position
    #   @param size Initial size
    #   @param manager Pointer to parent diagram manager
    def initialize(*args)

    end

  end

end
