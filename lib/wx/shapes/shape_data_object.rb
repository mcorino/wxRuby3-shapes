# Wx::SF::ShapeDataObject - shape data object class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  # Class encapsulating data object used during clipboard operations with shapes.
  class ShapeDataObject < Wx::DataObject

    DataFormatID = Wx::DataFormat.new('ShapeFrameWorkDataFormat1_0')

    # @overload initialize()
    #   Default constructor
    # @overload initialize(selection)
    #   User constructor
    #   @param [Array<Wx::SF::Shape>] selection List of shapes which should be stored in the data object
    def initialize(selection = nil)
      unless selection.nil? || (selection.is_a?(Array) && selection.all? { |e| e.is_a?(Shape) })
        raise SFException, 'Expected nil or Array<Wx::SF::Shape>'
      end
      super()
      @shapes = selection
      @data = nil
      @format = DataFormatID.get_type
    end

    def get_as_text
      if  @format == DataFormatID.get_type
        @data ||= (@shapes ? @shapes.serialize(format: :yaml) : nil)
      end
      @data || ''
    end

    def get_as_shapes
      if @format == Wx::DataFormatId::DF_TEXT || @format == Wx::DataFormatId::DF_UNICODETEXT
        @shapes ||= (@data && @data.size>0 ? FIRM.deserialize(@data, format: :yaml) : nil)
      end
      @shapes || []
    end

    # List all the formats that we support. By default, the first is
    # treated as the 'preferred' format; this can be overridden by
    # providing a get_preferred format.
    def get_all_formats(direction)
      [ DataFormatID, Wx::DF_TEXT, Wx::DF_UNICODETEXT ]
    end

    # Do setting the data
    def set_data(format, the_data)
      case format.get_type
      when DataFormatID.get_type
        @shapes = if the_data.size > 0
                    begin
                      FIRM.deserialize(the_data, format: :yaml)
                    rescue Exception
                      $stderr.puts "#{$!}\n#{$!.backtrace.join("\n")}"
                      return false
                    end
                  else
                    nil
                  end
        @data = nil
        @format = format.get_type
        true
      when Wx::DataFormatId::DF_TEXT, Wx::DataFormatId::DF_UNICODETEXT
        @data = the_data
        @shapes = nil
        @format = format.get_type
        true
      else
        false
      end
    end

    def get_data_size(format)
      case format.get_type
      when Wx::DataFormatId::DF_TEXT, Wx::DataFormatId::DF_UNICODETEXT
        @data ? @data.size : 0
      when DataFormatID.get_type
        get_as_text.bytesize
      else
        0
      end
    end

    # Do getting the data
    def get_data_here(format)
      case format.get_type
      when Wx::DataFormatId::DF_TEXT, Wx::DataFormatId::DF_UNICODETEXT
        @data
      when DataFormatID.get_type
        begin
          get_as_text
        rescue Exception
          $stderr.puts "#{$!}\n#{$!.backtrace.join("\n")}"
          nil
        end
      else
        nil
      end
    end

    # # Returns size of the data object
    # # @return [Integer]
    # def _get_data_size
    #   @data.bytesize
    # end
    #
    # # Exports data from data object.
    # # @return [Boolean] true on success, otherwise false
    # def _get_data
    #   @data
    # end
    #
    # # Function should inport data from data object from given buffer.
    # # @param [String] buf External input data buffer
    # # @return [Boolean] true on success, otherwise false
    # def _set_data(buf)
    #   @data = buf ? buf : ''
    #   true
    # end

  end

end
