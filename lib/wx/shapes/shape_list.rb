# Wx::SF::Shape - shape list class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/serializable'

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
          @index = enum.instance_variable_get('@index').dup
        elsif enum.is_a?(::Enumerable)
          @list = []
          @index = {}
          enum.each { |elem| self << elem }
        else
          @list = []
          @index = {}
          self << enum
        end
      else
        @list = []
        @index = {}
      end
    end

    # Iterates over contained shapes.
    # When a block given, passes each successive shape to the block.
    # Allows the array to be modified during iteration.
    # When no block given, returns a new ::Enumerator.
    # @yieldparam [Shape] shape
    # @return [self]
    def each(&block)
      @list.each(&block)
      self
    end

    # Recursively collects shapes and returns collection.
    # @param [Array<Shape>] collection container to return collected shapes in
    def all(collection = [])
      @list.inject(collection) { |list, shape| shape.instance_variable_get('@child_shapes').all(list << shape) }
    end

    # Returns true if the no shapes are contained, false otherwise.
    # @return [Boolean]
    def empty?
      @list.empty?
    end

    # Empties the shape list.
    # @return [self]
    def clear
      @list.clear
      @index.clear
      self
    end

    # Appends a new shape to the list if not yet in list.
    # @param [Shape] shape shape to add
    # @return [self]
    def append(shape)
      unless @index.has_key?(check_elem(shape).id)
        @list << shape
        @index[shape.id] = shape
      end
      self
    end
    alias :push :append
    alias :<< :append

    # Removes the first shape from the list (if any) and returns that.
    # @return [Shape,nil] removed shape or nil if list empty
    def shift
      return nil if @list.empty?
      @index.delete(@list.shift.id)
    end

    # Removes the last shape from the list (if any) and returns that.
    # @return [Shape,nil] removed shape or nil if list empty
    def pop
      return nil if @list.empty?
      @index.delete(@list.pop.id)
    end

    # Removes a shape matching the key given from the list and returns that.
    # @param [Shape,FIRM::Serializable::ID] key shape or shape ID to match
    # @return [Shape,nil] removed shape or nil if none matched
    def delete(key)
      if key.is_a?(Shape)
        return @list.delete(key) if @index.delete(key.id)
      elsif key.is_a?(FIRM::Serializable::ID)
        return @list.delete(@index.delete(key)) if @index.has_key?(key)
      end
      nil
    end

    # Returns true if a shape matches the given key or false if no shape matches.
    # @param [Shape,FIRM::Serializable::ID] key shape or shape ID to match
    # @param [Boolean] recursive pass true to search recursively, false for non-recursive
    # @return [Boolean]
    def include?(key, recursive = false)
      found = if key.is_a?(FIRM::Serializable::ID)
                @index.has_key?(key)
              else
                @list.include?(key)
              end
      found || (recursive && @list.any? { |child| child.instance_variable_get('@child_shapes').include?(key, recursive) })
    end

    # Returns the shape matching the given key or nil if no shape matches.
    # Does not modify the list.
    # @param [Integer,FIRM::Serializable::ID] key shape list index or shape ID to match
    # @param [Boolean] recursive pass true to search recursively, false for non-recursive
    # @return [Shape,nil] matched shape or nil if none matched
    def get(key, recursive = false)
      shape = if key.is_a?(FIRM::Serializable::ID)
                @index[key]
              else
                @list.at(key.to_i)
              end
      shape || (recursive && key.is_a?(FIRM::Serializable::ID) && find_child_shape(key, recursive))
    end
    alias :[] :get

    private

    # Find (first) child shape with given ID.
    # @param [FIRM::Serializable::ID] id Shape's ID
    # @param [Boolean] recursive pass true to search recursively, false for non-recursive
    # @return [Wx::SF::Shape, nil] shape if exists, otherwise nil
    def find_child_shape(id, recursive = false)
      child = nil
      @list.find { |shape| child = shape.find_child_shape(id, recursive) } && child
    end

    # Get shape array. Serialization only.
    # @return [Array<Shape>]
    def get_list
      @list
    end

    # Set shape array from deserialization.
    # @param [Array<Shape>] list
    def set_list(list)
      @list = list
      @list.each { |shape| @index[shape.id] = shape }
    end

    # Check intended list item
    # @param [Shape] shape intended list item
    # @return [Shape] checked shape
    def check_elem(shape)
      ::Kernel.raise TypeError, 'Expected a Wx::SF::Shape' unless shape.is_a?(Wx::SF::Shape)
      shape
    end

  end

end
