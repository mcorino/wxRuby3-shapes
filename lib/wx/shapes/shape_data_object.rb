# Wx::SF::ShapeDataObject - shape data object class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  # Class encapsulating data object used during clipboard operations with shapes.
  class ShapeDataObject < Wx::DataObjectSimpleBase

    DataFormatID = 'ShapeFrameWorkDataFormat1_0'

    # @overload initialize()
    #   Default constructor
    # @overload initialize(selection)
    #   User constructor
    #   @param [Array<Wx::SF::Shape>] selection List of shapes which should be stored in the data object
    def initialize(selection = nil)
      super(Wx::DataFormat.new(DataFormatID))
      @data = selection ? selection.serialize : ''
    end

    # Returns size of the data object
    # @return [Integer]
    def _get_data_size
      @data.bytesize
    end

    # Exports data from data object.
    # @return [Boolean] true on success, otherwise false
    def _get_data
      @data
    end

    # Function should inport data from data object from given buffer.
    # @param [String] buf External input data buffer
    # @return [Boolean] true on success, otherwise false
    def _set_data(buf)
      @data = buf ? buf : ''
      true
    end

  end

end
