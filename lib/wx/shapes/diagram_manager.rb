# Wx::SF::DiagramManager - diagram manager class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/diagram'

module Wx::SF

  class DiagramManager

    Version = ::Struct.new('Version', :major, :minor, :release, :pre_release)

    def initialize
      md = /(\d+)\.(\d+)\.(\d+)(.+)?/.match(Wx::SF::VERSION)
      @version = Version.new(md[1], md[2], md[3], md[4])
      @diagram = nil
    end

    attr_reader :version, :diagram

  end

end
