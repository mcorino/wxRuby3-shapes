# Wx::SF::Serializer - shape serializer module
# Copyright (c) M.J.N. Corino, The Netherlands

require 'set'

module Wx::SF

  module Serializable

    class Property
      def initialize(klass, prop, proc=nil, force: false, handler: nil, &block)
        ::Kernel.raise ArgumentError, "Invalid property id [#{prop}]" unless ::String === prop || ::Symbol === prop
        ::Kernel.raise ArgumentError, "Duplicate property id [#{prop}]" if klass.has_serializer_property?(prop)
        @klass = klass
        @id = prop.to_sym
        @forced = force
        if block || handler
          if handler
            ::Kernel.raise ArgumentError,
                           "Invalid property handler #{handler} for #{prop}" unless ::Proc === handler || ::Symbol === handler
            if handler.is_a?(::Proc)
              ::Kernel.raise ArgumentError, "Invalid property block #{proc} for #{prop}" unless block.arity == -3
              @getter = ->(obj) { handler.call(@id, obj) }
              @setter = ->(obj, val) { handler.call(@id, obj, val) }
            else
              @getter = ->(obj) { obj.send(handler, @id) }
              @setter = ->(obj, val) { obj.send(handler, @id, val) }
            end
          else
            # any property block MUST accept 2 or 3 args; property name, instance and value (for setter)
            ::Kernel.raise ArgumentError, "Invalid property block #{proc} for #{prop}" unless block.arity == -3
            @getter = ->(obj) { block.call(@id, obj) }
            @setter = ->(obj, val) { block.call(@id, obj, val) }
          end
        elsif proc
          ::Kernel.raise ArgumentError,
                         "Invalid property proc #{proc} for #{prop}" unless ::Proc === proc || ::Symbol === proc
          if ::Proc === proc
            # any property proc should be callable with a single arg (instance)
            @getter = proc
            # a property proc combining getter/setter functionality should accept a single or more args (instance + value)
            @setter = (proc.arity == -2) ? proc : nil
          else
            @getter = ->(obj) { obj.send(proc) }
            @setter = ->(obj, val) { obj.send(proc, val) }
          end
        end
      end

      attr_reader :id

      def serialize(obj, data, excludes)
        unless excludes.include?(@id)
          val = getter.call(obj)
          unless Serializable === val && val.serialize_disabled? && !@forced
            data[@id] = case val
                        when ::Array
                          val.select { |elem| !(Serializable === elem && elem.serialize_disabled?) }
                        when ::Set
                          ::Set.new(val.select { |elem| !(Serializable === elem && elem.serialize_disabled?) })
                        else
                          val
                        end
          end
        end
      end

      def deserialize(obj, data)
        if data.has_key?(@id)
          setter.call(obj, data[@id])
        end
      end

      def get(obj)
        getter.call(obj)
      end

      def get_method(id)
        begin
          @klass.instance_method(id)
        rescue NameError
          nil
        end
      end
      private :get_method

      def getter
        unless @getter
          inst_meth = get_method(@id)
          inst_meth = get_method("get_#{@id}") unless inst_meth
          if inst_meth
            @getter = ->(obj) { inst_meth.bind(obj).call }
          else
            return self.method(:getter_fail)
          end
        end
        @getter
      end
      private :getter

      def setter
        unless @setter
          inst_meth = get_method("#{@id}=")
          inst_meth = get_method("set_#{@id}") unless inst_meth
          unless inst_meth
            im = get_method(@id)
            if im && im.arity == -1
              inst_meth = im
            else
              inst_meth = nil
            end
          end
          if inst_meth
            @setter = ->(obj, val) { inst_meth.bind(obj).call(val) }
          else
            return self.method(:setter_noop)
          end
        end
        @setter
      end
      private :setter

      def getter_fail(obj)
        ::Kernel.raise RuntimeError, "Missing getter for property #{@id} of #{@klass}"
      end
      private :getter_fail

      def setter_noop(_, _)
        # do nothing
      end
      private :setter_noop
    end

    # Serializable unique ids.
    # This class makes sure to maintain uniqueness across serialization/deserialization cycles
    # and keeps all shared instances within a single (serialized/deserialized) object set in
    # sync.
    class ID; end

    class << self

      def serializables
        @serializables ||= ::Set.new
      end

      def formatters
        @formatters ||= {}
      end
      private :formatters

      # Registers a serialization formatting engine
      # @param [Symbol,String] format format id
      # @param [Object] engine formatting engine
      def register(format, engine)
        if formatters.has_key?(format.to_s.downcase)
          ::Kernel.raise ArgumentError,
                         "Duplicate serialization formatter registration for #{format}"
        end
        formatters[format.to_s.downcase] = engine
      end

      # Return a serialization formatting engine
      # @param [Symbol,String] format format id
      # @return [Object] formatting engine
      def [](format)
        formatters[format.to_s.downcase]
      end

      def default_format
        @default_format ||= :json
      end

      def default_format=(format)
        @default_format = format
      end

    end

    # Mixin module for classes that get Wx::SF::Serializable included.
    # This module is used to extend the class methods of the serializable class.
    module SerializeClassMethods

      # Adds (a) serializable property(-ies) for instances of his class (and derived classes)
      # @overload property(*props, force: false)
      #   Specifies one or more serialized properties.
      #   The serialization framework will determine the availability of setter and getter methods
      #   automatically by looking for methods <code>"#{prop_id}=(v)"</code>, <code>"set_#{prop_id}(v)"</code> or <code>"#{prop}(v)"</code>
      #   for setters and <code>"#{prop_id}()"</code> or <code>"get_#{prop_id}"</code> for getters.
      #   @param [Symbol,String] props one or more ids of serializable properties
      #   @param [Boolean] force overrides any #disable_serialize for the properties specified
      # @overload property(hash, force: false)
      #   Specifies one or more serialized properties with associated setter/getter method ids/procs/lambda-s.
      #   @example
      #     property(
      #       prop_a: ->(obj, *val) {
      #                 obj.my_prop_a_setter(val.first) unless val.empty?
      #                 obj.my_prop_a_getter
      #               },
      #       prop_b: Proc.new { |obj, *val|
      #                 obj.my_prop_b_setter(val.first) unless val.empty?
      #                 obj.my_prop_b_getter
      #               },
      #       prop_c: :serialization_method)
      #   Procs with setter support MUST accept 1 or 2 arguments (1 for getter, 2 for setter).
      #   @note Use `*val` to specify the optional value argument for setter requests instead of `val=nil`
      #         to be able to support setting explicit nil values.
      #   @param [Hash] hash a hash of pairs of property ids and getter/setter procs
      #   @param [Boolean] force overrides any #disable_serialize for the properties specified
      # @overload property(*props, force: false, handler: nil, &block)
      #   Specifies one or more serialized properties with a getter/setter handler proc/method/block.
      #   The getter/setter proc or block should accept either 2 (property id and object for getter) or 3 arguments
      #   (property id, object and value for setter) and is assumed to handle getter/setter requests
      #   for all specified properties.
      #   The getter/setter method should accept either 1 (property id for getter) or 2 arguments
      #   (property id and value for setter) and is assumed to handle getter/setter requests
      #   for all specified properties.
      #   @example
      #     property(:property_a, :property_b, :property_c) do |id, obj, *val|
      #       case id
      #         when :property_a
      #           ...
      #         when :property_b
      #           ...
      #         when :property_c
      #           ...
      #       end
      #     end
      #   @note Use `*val` to specify the optional value argument for setter requests instead of `val=nil`
      #         to be able to support setting explicit nil values.
      #   @param [Symbol,String] props one or more ids of serializable properties
      #   @param [Boolean] force overrides any #disable_serialize for the properties specified
      #   @yieldparam [Symbol,String] id property id
      #   @yieldparam [Object] obj object instance
      #   @yieldparam [Object] val optional property value to set in case of setter request
      def property(*props, **kwargs, &block)
        forced = !!kwargs.delete(:force)
        if block || kwargs[:handler]
          props.each do |prop|
            serializer_properties << Property.new(self, prop, force: forced, handler: kwargs[:handler], &block)
          end
        else
          props.flatten.each do |prop|
            if ::Hash === prop
              prop.each_pair do |pn, pp|
                serializer_properties << Property.new(self, pn, pp, force: forced)
              end
            else
              serializer_properties << Property.new(self, prop, force: forced)
            end
          end
          unless kwargs.empty?
            kwargs.each_pair do |pn, pp|
              serializer_properties << Property.new(self, pn, pp, force: forced)
            end
          end
        end
      end
      alias :properties :property
      alias :contains :property

      # excludes a serializable property for instances of this class
      # (mostly/only useful to exclude properties from base classes which
      #  do not require serialization for derived class)
      def excluded_property(*props)
        excluded_serializer_properties.merge props.flatten.collect { |prop| prop.to_s }
      end
      alias :excluded_properties :excluded_property
      alias :excludes :excluded_property

      # Creates a new instance for subsequent deserialization and optionally initialize
      # it using the given data hash.
      # The default implementation creates a new instance using the default constructor
      # (no arguments, no initialization) and leaves the initialization to a subsequent call
      # to the instance method #from_serialized(data).
      # Classes that do not support a default constructor can override this class method and
      # implement a custom creation scheme.
      # @param [Hash] _data hash containing deserialized property data (symbol keys)
      # @return [Object] the newly created object
      def create_for_deserialize(_data)
        self.new
      end

    end

    # Mixin module for classes that get Wx::SF::Serializable included.
    # This module is used to extend the instance methods of the serializable class.
    module SerializeInstanceMethods

      # Serialize this object
      # @overload serialize(pretty: false, format: Serializable.default_format)
      #   @param [Boolean] pretty if true specifies to generate pretty formatted output if possible
      #   @param [Symbol,String] format specifies output format
      #   @return [String] serialized data
      # @overload serialize(io, pretty: false, format: Serializable.default_format)
      #   @param [IO] io output stream to write serialized data to
      #   @param [Boolean] pretty if true specifies to generate pretty formatted output if possible
      #   @param [Symbol,String] format specifies output format
      #   @return [IO]
      def serialize(io = nil, pretty: false, format: Serializable.default_format)
        Serializable[format].dump(self, io, pretty: pretty)
      end

      # Returns true if regular serialization for this object has been disabled, false otherwise (default).
      # Disabled serialization can be overridden for single objects (not objects maintained in property containers
      # like arrays and sets).
      # @return [Boolean]
      def serialize_disabled?
        !!@serialize_disabled # true for any value but false
      end

      # Disables serialization for this object as a single property or as part of a property container
      # (array or set).
      # @return [void]
      def disable_serialize
        # by default unset (nil) so serializing enabled
        @serialize_disabled = true
      end

      # @!method for_serialize(hash, excludes = Set.new)
      #   Serializes the properties of a serializable instance to the given hash
      #   except when the property id is included in excludes.
      #   @param [Hash] hash property serialization hash
      #   @param [Set] excludes set with excluded property ids
      #   @return [Hash] property serialization hash

      # @!method from_serialized(hash)
      #   Restores the properties of a deserialized instance.
      #   @param [Hash] hash deserialized properties hash
      #   @return [self]

    end

    # Serialize the given object
    # @overload serialize(obj, pretty: false, format: Serializable.default_format)
    #   @param [Object] obj object to serialize
    #   @param [Boolean] pretty if true specifies to generate pretty formatted output if possible
    #   @param [Symbol,String] format specifies output format
    #   @return [String] serialized data
    # @overload serialize(obj, io, pretty: false, format: Serializable.default_format)
    #   @param [Object] obj object to serialize
    #   @param [IO] io output stream to write serialized data to
    #   @param [Boolean] pretty if true specifies to generate pretty formatted output if possible
    #   @param [Symbol,String] format specifies output format
    #   @return [IO]
    def self.serialize(obj, io = nil, pretty: false, format: Serializable.default_format)
      self[format].dump(obj, io, pretty: pretty)
    end

    # Deserializes object from source data
    # @param [IO,String] source source data (stream)
    # @param [Symbol, String] format data format of source
    # @return [Object] deserialized object
    def self.deserialize(source, format: Serializable.default_format)
      self[format].load(::IO === source || source.respond_to?(:read) ? source.read : source)
    end

    def self.included(base)
      ::Kernel.raise RuntimeError, "#{self} should only be included in classes" if base.instance_of?(::Module)

      # register as serializable class
      Serializable.serializables << base

      return if base == Serializable::ID # special case which does not need the rest

      # provide serialized property definition support

      # provide serialized classes with their own serialized properties (exclusion) list
      base.singleton_class.class_eval do
        def serializer_properties
          @serializer_props ||= []
        end
        def excluded_serializer_properties
          @excluded_serializer_props ||= ::Set.new
        end
      end
      # add class methods
      base.extend(SerializeClassMethods)

      # add instance property (de-)serialization methods for base class
      base.class_eval <<~__CODE
        def for_serialize(hash, excludes = ::Set.new)
          hash[:'@explicit'] = true if serialize_disabled? # mark explicit serialize overriding disabling
          #{base.name}.serializer_properties.each { |prop, h| prop.serialize(self, hash, excludes) }
          hash 
        end
        protected :for_serialize

        def from_serialized(hash)
          disable_serialize if hash[:'@explicit'] # re-instate serialization disabling
          #{base.name}.serializer_properties.each { |prop| prop.deserialize(self, hash) }
          self
        end
        protected :from_serialized

        def self.has_serializer_property?(id)
          self.serializer_properties.any? { |p| p.id == id.to_sym } 
        end
        __CODE
      # add inheritance support
      base.class_eval do
        def self.inherited(derived)
          # add instance property (de-)serialization methods for derived classes
          derived.class_eval <<~__CODE
            module SerializerMethods 
              def for_serialize(hash, excludes = ::Set.new)
                hash = super(hash, excludes | #{derived.name}.excluded_serializer_properties) 
                #{derived.name}.serializer_properties.each { |prop| prop.serialize(self, hash, excludes) }
                hash 
              end
              protected :for_serialize
  
              def from_serialized(hash)
                #{derived.name}.serializer_properties.each { |prop| prop.deserialize(self, hash) }
                super(hash)
              end
              protected :from_serialized
            end
            include SerializerMethods
            __CODE
          derived.class_eval do
            def self.has_serializer_property?(id)
              self.serializer_properties.any? { |p| p.id == id.to_sym } || self.superclass.has_serializer_property?(id)
            end
          end

          # register as serializable class
          Serializable.serializables << derived
        end
      end

      # add instance serialization method
      base.include(SerializeInstanceMethods)
    end

  end # module Serializable

end # module Wx::SF

Dir[File.join(__dir__, 'serializer', '*.rb')].each { |fnm| require "wx/shapes/serializer/#{File.basename(fnm)}" }
Dir[File.join(__dir__, 'serialize', '*.rb')].each { |fnm| require "wx/shapes/serialize/#{File.basename(fnm)}" }
