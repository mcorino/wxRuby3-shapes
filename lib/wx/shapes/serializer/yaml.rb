# Wx::SF::Serializer - shape serializer module
# Copyright (c) M.J.N. Corino, The Netherlands

require 'yaml'
require 'set'
require 'ostruct'

module Wx::SF

  module Serializable

    module YAML

      class << self
        def serializables
          [Date, DateTime, Exception, Range, Regexp, Struct, Symbol, Time, Set, OpenStruct]
        end
      end

      module YamlSerializePatch
        def revive(klass, node)
          if Wx::SF::Serializable > klass
            s = register(node, klass.create_for_deserialize)
            init_with(s, revive_hash({}, node, true), node)
          else
            super
          end
        end
      end

      class RestrictedRelaxed < ::YAML::ClassLoader
        def initialize(classes)
          @classes = classes
          @allow_struct = @classes.include?('Struct')
          super()
        end

        private

        def find(klassname)
          if @classes.include?(klassname)
            super
          elsif @allow_struct && klassname.start_with?('Struct::') && ::Struct > super
            @cache[klassname]
          else
            raise DisallowedClass.new('load', klassname)
          end
        end
      end

      def self.dump(obj, io=nil, pretty: false)
        ::YAML.dump(obj, io)
      end

      def self.load(source)
        result = ::YAML.parse(source, filename: nil)
        return nil unless result

        allowed_classes =(YAML.serializables + Serializable.serializables).map(&:to_s)
        class_loader = RestrictedRelaxed.new(allowed_classes)
        scanner      = ::YAML::ScalarScanner.new(class_loader, strict_integer: false)
        visitor = ::YAML::Visitors::NoAliasRuby.new(scanner, class_loader, symbolize_names: false, freeze: false)
        visitor.extend(YamlSerializePatch)
        result = visitor.accept result
        result
      end

    end

    # extend instance serialization methods
    module SerializeInstanceMethods

      def encode_with(coder)
        for_serialize(coder)
      end

      def init_with(coder)
        from_serialized(coder.map)
      end

    end

    register(:yaml, YAML)

  end

end
