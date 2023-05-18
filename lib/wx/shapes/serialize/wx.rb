# Wx::SF::Serializer - Wx class serializer extensions
# Copyright (c) M.J.N. Corino, The Netherlands

class Wx::Point

  include Wx::SF::Serializable

  properties :x, :y

end

class Wx::RealPoint

  include Wx::SF::Serializable

  properties :x, :y

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
