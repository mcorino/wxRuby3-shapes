# Wx::SF::Serializer - Ruby core serializer extensions
# Copyright (c) M.J.N. Corino, The Netherlands

# we do not include Wx::SF::Serializer::SerializeMethod here as that would
# also extend these classes with the engine specific extension that we do not
# need or want here

class Array
  def serialize(io = nil, pretty: false, format: Wx::SF::Serializable.default_format)
    Wx::SF::Serializable[format].dump(self, io, pretty: pretty)
  end
end

class Hash
  def serialize(io = nil, pretty: false, format: Wx::SF::Serializable.default_format)
    Wx::SF::Serializable[format].dump(self, io, pretty: pretty)
  end
end

class Struct
  def serialize(io = nil, pretty: false, format: Wx::SF::Serializable.default_format)
    Wx::SF::Serializable[format].dump(self, io, pretty: pretty)
  end
end

require 'set'

class Set
  def serialize(io = nil, pretty: false, format: Wx::SF::Serializable.default_format)
    Wx::SF::Serializable[format].dump(self, io, pretty: pretty)
  end
end

require 'ostruct'

class OpenStruct
  def serialize(io = nil, pretty: false, format: Wx::SF::Serializable.default_format)
    Wx::SF::Serializable[format].dump(self, io, pretty: pretty)
  end
end
