# Wx::SF::Serializer - shape serializer module
# Copyright (c) M.J.N. Corino, The Netherlands

require 'json'
require 'json/add/core'
require 'json/add/set'
require 'json/add/ostruct'

module Wx::SF

  module Serializable

    module JSON

      class << self
        def serializables
          ::Set.new [NilClass, TrueClass, FalseClass, Integer, Float, String, Array, Hash,
                           Date, DateTime, Exception, Range, Regexp, Struct, Symbol, Time, Set, OpenStruct]
        end

        def safe_deserialize?
          @safe_deserialize
        end

        def safe_deserialize=(f)
          @safe_deserialize = !!f
        end
      end

      class StringKeyHash < ::Hash
        def [](key)
          super(key.to_s)
        end
        def has_key?(key)
          super(key.to_s)
        end
      end

      def self.dump(obj, io=nil, pretty: false)
        if pretty
          if io
            io.write(::JSON.pretty_generate(obj))
            io
          else
            ::JSON.pretty_generate(obj)
          end
        else
          ::JSON.dump(obj, io)
        end
      end

      def self.load(source)
        begin
          # enable safe deserializing
          self.safe_deserialize = true
          ::JSON.parse!(source, {create_additions: true, object_class: StringKeyHash})
        ensure
          self.safe_deserialize = false
        end
      end

    end

    # extend serialization class methods
    module SerializeClassMethods

      def json_create(object)
        create_for_deserialize.__send__(:from_serialized, object['data'])
      end

    end

    # extend instance serialization methods
    module SerializeInstanceMethods

      def to_json(*args)
        {
          ::JSON.create_id => self.class.name,
          'data' => for_serialize({})
        }.to_json(*args)
      end

    end

    register(Serializable.default_format, JSON)

  end

end

class ::Class

  # override this to be able to do safe deserializing
  def json_creatable?
    if Wx::SF::Serializable::JSON.safe_deserialize?
      return false unless Wx::SF::Serializable::JSON.serializables.include?(self) ||
                          Wx::SF::Serializable.serializables.include?(self) ||
                          ::Struct > self
    end
    respond_to?(:json_create)
  end

end
