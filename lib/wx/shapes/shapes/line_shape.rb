# Wx::SF::LineShape - line shape class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  class LineShape < Shape

    # Default values
    module DEFAULT
      # Default value of undefined ID. 
      UNKNOWNID = nil
      # Default value of LineShape @pen data member.
      PEN = ->() { Wx::Pen.new(Wx::BLACK) }
      # Default value of LineShape @dock_point data member.
      DOCKPOINT = 0
      # Default value of LineShape @dock_point data member (start line point).
      DOCKPOINT_START = -1
      # Default value of LineShape @dock_point data member (end line point).
      DOCKPOINT_END = -2
      # Default value of LineShape @dock_point data member (middle dock point).
      DOCKPOINT_CENTER = 2**64
      # Default value of LineShape @src_offset and LineShape @trg_offset data members.
      OFFSET = Wx::RealPoint.new(-1, -1)
      # Default value of LineShape @src_point and LineShape @trg_point data members.
      DEFAULTPOINT = Wx::RealPoint.new(0, 0)
      # Default value of LineShape @stand_alone data member.
      STANDALONE = false
    end

    # The modes in which the line shape can stay.
    class LINEMODE < Wx::Enum
      READY = self.new(0)
      UNDERCONSTRUCTION = self.new(1)
      SRCCHANGE = self.new(2)
      TRGCHANGE = self.new(3)
    end


  end

end
