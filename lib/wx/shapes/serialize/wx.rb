# Wx::SF::Serializer - Wx class serializer extensions
# Copyright (c) M.J.N. Corino, The Netherlands

class Wx::Point

  include FIRM::Serializable

  properties :x, :y

end

class Wx::RealPoint

  include FIRM::Serializable

  properties :x, :y

end

class Wx::Size

  include FIRM::Serializable

  properties :width, :height

end

class Wx::Rect

  include FIRM::Serializable

  properties :x, :y, :width, :height

end

class Wx::Enum

  include FIRM::Serializable

  property value: ->(enum) { enum.to_i }

  def init_from_serialized(data)
    self.__send__(:initialize, data[:value] || 0)
  end

end

class Wx::Colour

  include FIRM::Serializable

  property :colour => ->(col, *val) { col.set(*val.first) unless val.empty?; [col.red, col.green, col.blue, col.alpha] }

end

# need to add this Enum explicitly as it was initially defined before we extended the Wx::Enum class above
class Wx::BrushStyle

  include FIRM::Serializable

  property value: ->(enum) { enum.to_i }

  def init_from_serialized(data)
    self.__send__(:initialize, data[:value] || 0)
  end

end

class Wx::Brush

  include FIRM::Serializable

  property :colour, :style

end

# need to add this Enum explicitly as it was initially defined before we extended the Wx::Enum class above
class Wx::PenStyle

  include FIRM::Serializable

  property value: ->(enum) { enum.to_i }

  def init_from_serialized(data)
    self.__send__(:initialize, data[:value] || 0)
  end

end

class Wx::Pen

  include FIRM::Serializable

  property :colour, :width, :style

end

class Wx::Font

  include FIRM::Serializable

  property font_info: ->(font, *info) { font.set_native_font_info_user_desc(info.shift) unless info.empty?; font.get_native_font_info_user_desc }

end

class Wx::BitmapType

  include FIRM::Serializable

  property value: ->(enum) { enum.to_i }

  def init_from_serialized(data)
    self.__send__(:initialize, data[:value] || 0)
  end

end
