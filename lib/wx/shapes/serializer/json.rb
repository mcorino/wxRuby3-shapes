# Wx::SF::Serializer - shape serializer module
# Copyright (c) M.J.N. Corino, The Netherlands

require 'json'
require 'json/add/core'
require 'json/add/set'
require 'json/add/ostruct'

module Wx::SF

  module Serializable

    module JSON

      class HashMap
        include Wx::SF::Serializable

        property :hash_list

        def initialize(hash = nil)
          @hash = hash
        end

        attr_reader :hash

        def get_hash_list
          @hash.to_a
        end
        private :get_hash_list

        def set_hash_list(arr)
          @hash = arr.to_h
        end
      end

      class ObjectHash < ::Hash
        def self.[](arg)
          arg.to_hash.each_pair { |k,v| self[k] = v }
        end

        def [](key)
          (v = super(key.to_s)).is_a?(HashMap) ? v.hash : v
        end
        def has_key?(key)
          super(key.to_s)
        end
        def []=(key, val)
          super(key.to_s, val.instance_of?(::Hash) ? HashMap.new(val) : val)
        end
      end

      class << self
        def serializables
          ::Set.new [NilClass, TrueClass, FalseClass, Integer, Float, String, Array, Hash,
                           Date, DateTime, Exception, Range, Regexp, Struct, Symbol, Time, Set, OpenStruct]
        end

        TLS_SAFE_DESERIALIZE_KEY = :wx_sf_json_safe_deserialize.freeze
        private_constant :TLS_SAFE_DESERIALIZE_KEY

        TLS_PARSE_STACK_KEY = :wx_sf_json_parse_stack.freeze
        private_constant :TLS_PARSE_STACK_KEY

        def safe_deserialize
          ::Thread.current[TLS_SAFE_DESERIALIZE_KEY] ||= []
        end
        private :safe_deserialize

        def start_safe_deserialize
          safe_deserialize.push(true)
        end

        def end_safe_deserialize
          safe_deserialize.pop
        end

        def parse_stack
          ::Thread.current[TLS_PARSE_STACK_KEY] ||= []
        end
        private :parse_stack

        def start_parse
          parse_stack.push(safe_deserialize.pop)
        end

        def end_parse
          unless (val = parse_stack.pop).nil?
            safe_deserialize.push(val)
          end
        end

        def safe_parsing?
          !!parse_stack.last
        end
      end

      def self.dump(obj, io=nil, pretty: false)
        obj = obj.instance_of?(::Hash) ? HashMap.new(obj) : obj
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
          # initialize ID restoration map
          Serializable::ID.init_restoration_map
          # enable safe deserializing
          self.start_safe_deserialize
          result = ::JSON.parse!(source,
                                 {create_additions: true,
                                  object_class: Serializable::JSON::ObjectHash})
          result.is_a?(HashMap) ? result.hash : result
        ensure
          # reset safe deserializing
          self.end_safe_deserialize
          # reset ID restoration map
          Serializable::ID.clear_restoration_map
        end
      end

    end

    # extend serialization class methods
    module SerializeClassMethods

      def json_create(object)
        create_for_deserialize(data = object['data']).__send__(:from_serialized, data)
      end

    end

    # extend instance serialization methods
    module SerializeInstanceMethods

      def to_json(*args)
        {
          ::JSON.create_id => self.class.name,
          'data' => for_serialize(Serializable::JSON::ObjectHash.new)
        }.to_json(*args)
      end

    end

    class ID

      def self.json_create(object)
        create_for_deserialize(data = object['data'])
      end

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

module ::JSON
  class << self

    alias :pre_wxsf_parse! :parse!
    def parse!(*args, **kwargs)
      begin
        # setup parsing stack for safe or normal deserializing
        # the double bracketing provided from Wx::SF::Serializable::JSON#load and here
        # makes sure to support both nested Wx::SF deserializing as well as nested
        # hybrid deserializing (Wx::SF -> common JSON -> ...)
        Wx::SF::Serializable::JSON.start_parse
        pre_wxsf_parse!(*args, **kwargs)
      ensure
        # reset parsing stack
        Wx::SF::Serializable::JSON.end_parse
      end
    end

  end
end

class ::Class

  # override this to be able to do safe deserializing
  def json_creatable?
    if Wx::SF::Serializable::JSON.safe_parsing?
      return false unless Wx::SF::Serializable::JSON.serializables.include?(self) ||
                          Wx::SF::Serializable.serializables.include?(self) ||
                          ::Struct > self
    end
    respond_to?(:json_create)
  end

end
