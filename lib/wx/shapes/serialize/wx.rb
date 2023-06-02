# Wx::SF::Serializer - Wx class serializer extensions
# Copyright (c) M.J.N. Corino, The Netherlands

class Wx::Point

  include Wx::SF::Serializable

  properties :x, :y

end

class Wx::RealPoint

  include Wx::SF::Serializable

  properties :x, :y

  def to_s
    "#<Wx::RealPoint:#{Wx::ptr_addr(self)} (#{x}, #{y})>"
  end
end

class Wx::Size

  include Wx::SF::Serializable

  properties :width, :height

end

class Wx::Rect

  include Wx::SF::Serializable

  properties :x, :y, :width, :height

end

class Wx::Enum

  include Wx::SF::Serializable

  property :value => ->(enum) { enum.to_i }

  def self.create_for_deserialize(data)
    self.new(data[:value] || 0)
  end

end

class Wx::Colour

  include Wx::SF::Serializable

  property :colour => ->(col, *val) { col.set(*val.first) unless val.empty?; [col.red, col.green, col.blue, col.alpha] }

end

# need to add this Enum explicitly as it was initially defined before we extended the Wx::Enum class above
class Wx::BrushStyle

  property :value => ->(enum) { enum.to_i }

  include Wx::SF::Serializable

end

class Wx::Brush

  include Wx::SF::Serializable

  property :colour, :style

end

# need to add this Enum explicitly as it was initially defined before we extended the Wx::Enum class above
class Wx::PenStyle

  property :value => ->(enum) { enum.to_i }

  include Wx::SF::Serializable

end

class Wx::Pen

  include Wx::SF::Serializable

  property :colour, :width, :style

end
