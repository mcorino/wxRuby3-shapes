# Wx::SF::Shape - shape list class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/serializable'
require 'set'

module Wx::SF

  # This class implements an indexed container for unique, non-nil, shapes (no duplicates).
  class ShapeList

    include FIRM::Serializable
    include ::Enumerable

    property :list

    # Constructor.
    # @param [ShapeList,::Enumerable,Shape,nil] enum shape container to copy, single shape to add or nil
    def initialize(enum = nil)
      if enum
        if enum.is_a?(ShapeList)
          @list = enum.instance_variable_get('@list').dup
        elsif enum.is_a?(::Enumerable)
          @list = ::Set.new
          enum.each { |elem| self << elem }
        else
          @list = ::Set.new
          self << enum
        end
      else
        @list = ::Set.new
      end
    end

    # Iterates over contained shapes.
    # When a block given, passes each successive shape to the block.
    # Allows the array to be modified during iteration.
    # When no block given, returns a new ::Enumerator.
    # @yieldparam [Shape] shape
    # @return [self]
    def each(&block)
      if block_given?
        @list.each(&block)
        self
      else
        @list.each
      end
    end

    # Recursively collects shapes and returns collection.
    # @param [Array<Shape>] collection container to return collected shapes in
    def all(collection = [])
      @list.inject(collection.concat(@list.to_a)) { |list, shape| shape.instance_variable_get('@child_shapes').all(list) }
    end

    # Returns true if no shapes are contained, false otherwise.
    # @return [Boolean]
    def empty?
      @list.empty?
    end

    # Empties the shape list.
    # @return [self]
    def clear
      @list.clear
      self
    end

    # Appends a new shape to the list if not yet in list.
    # Does *not* perform a recursive check.
    # @param [Shape] shape shape to add
    # @return [self]
    def append(shape)
      unless @list.include?(check_elem(shape))
        @list << shape
      end
      self
    end
    alias :push :append
    alias :<< :append

    # Removes the given shape from the list and returns that.
    # @param [Shape] shape shape to match
    # @return [Shape,nil] removed shape or nil if none matched
    def delete(shape)
      if @list.include?(check_elem(shape))
        @list.delete(shape)
        shape
      else
        nil
      end
    end

    # Returns true if the given shape is included in the list.
    # Performs a recursive search in case :recursive is true.
    # @param [Shape] shape shape to match
    # @param [Boolean] recursive pass true to search recursively, false for non-recursive
    # @return [Boolean]
    def include?(shape, recursive = false)
      found = @list.include?(check_elem(shape))
      found || (recursive && @list.any? { |child| child.include_child_shape?(shape, recursive) })
    end

    private

    # Get shape set. Serialization only.
    # @return [Set<Shape>]
    def get_list
      @list
    end

    # Set shape set from deserialization.
    # @param [Set<Shape>] list
    def set_list(list)
      @list = list
    end

    # Check intended list item
    # @param [Shape] shape intended list item
    # @return [Shape] checked shape
    def check_elem(shape)
      ::Kernel.raise TypeError, "Expected a Wx::SF::Shape, got #{shape}" unless shape.is_a?(Wx::SF::Shape)
      shape
    end

  end

end
