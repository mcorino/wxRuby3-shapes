# Wx::SF::BoxShape - box shape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes/shapes/rect_shape'
require 'wx/shapes/shapes/manager_shape'

module Wx::SF

  # Class encapsulates a rectangular shape derived from Wx::SF::RectShape class which acts as a box-shaped
  # container able to manage other assigned child shapes (it can control their position). The managed
  # shapes are stacked into defined box (slots) according to it's primary orientation with a behaviour similar to
  # classic Wx::BoxSizer class. The box will be automatically resized along it's primary axis to accommodate
  # the combined sizes of the managed shapes. The minimum size of the box along it's secondary axis is
  # determined by the maximum size of the managed shapes.
  # When adding or removing shapes the stack of shapes will always be kept contiguous (without empty slots).
  # Managed shapes will never be resized along the primary axis but may be resized and/or positioned along
  # the secondary axis according to the contained shape's alignment setting (EXPAND).
  class BoxShape < RectShape

    include ManagerShape

    # Orientation values
    class ORIENTATION < Wx::Enum
      HORIZONTAL = self.new(0)
      VERTICAL = self.new(1)
    end

    # Default values
    class DEFAULT
      # default box orientation
      ORIENTATION = ORIENTATION::HORIZONTAL
      # Default value of GridShape @cell_space data member.
      SPACING  = 3
    end

    class << self

      # Returns the minimum size for *empty* boxes
      # @return [Wx::Size]
      def get_min_size
        @min_size ||= Wx::Size.new(20, 20)
      end
      alias :min_size :get_min_size

      # Sets the minimum size for *empty* boxes
      # @overload set_min_size(sz)
      #   @param [Wx::Size] sz
      # @overload set_min_size(w, h)
      #   @param [Integer] w
      #   @param [Integer] h
      def set_min_size(arg1, arg2 = nil)
        @min_size = if arg2.nil?
                      raise ArgumentError, 'Expected Wx::Size' unless Wx::Size === arg1
                      arg1
                    else
                      Wx::Size.new(arg1, arg2)
                    end
      end
      alias :min_size= :set_min_size

    end

    property :spacing, :orientation, :slots

    # Constructor.
    # @param [Wx::RealPoint,Wx::Point] pos Initial position
    # @param [Wx::RealPoint,Wx::Point,Wx::Size] size Initial size
    # @param [Wx::SF::BoxShape::ORIENTATION] orientation box orientation
    # @param [Integer] spacing Additional space between managed shapes
    # @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(pos = Shape::DEFAULT::POSITION, size = RectShape::DEFAULT::SIZE, orientation: DEFAULT::ORIENTATION, spacing: DEFAULT::SPACING, diagram: nil)
      super(pos, size, diagram: diagram)
      @orientation = orientation || DEFAULT::ORIENTATION
      @spacing = spacing || 0
      @slots = []
    end

    # Get the box shape orientation.
    # @return [Wx::SF::BoxShape::ORIENTATION]
    def get_orientation
      @orientation
    end
    alias :orientation :get_orientation

    # Get number of filled slots (i.e. managed shapes)
    # @return [Integer]
    def get_slot_count
      @slots.size
    end
    alias :slot_count :get_slot_count

    # Set space between slots (managed shapes).
    # @param [Integer] spacing Spacing size
    # @return [Integer] new spacing size
    def set_spacing(spacing)
      @spacing = spacing
    end
    alias :spacing= :set_spacing

    # Get space between slots (managed shapes).
    # @return [Integer] Spacing size
    def get_spacing
      @spacing
    end
    alias :spacing :get_spacing

    # Iterate all slots. If a block is given passes slot index and shape for each slot to block.
    # Returns Enumerator if no block given.
    # @overload each_slot()
    #   @return [Enumerator]
    # @overload each_slot(&block)
    #   @yieldparam [Integer] slot
    #   @yieldparam [Shape,nil] shape
    #   @return [Object]
    def each_slot(&block)
      if block
        @slots.each_with_index do |shape, slot|
          block.call(slot, shape)
        end
      else
        ::Enumerator.new do |y|
          @slots.each_with_index do |shape, slot|
            y << [slot, shape]
          end
        end
      end
    end

    # Get managed shape specified by slot index.
    # @param [Integer] slot slot index of requested shape
    # @return [Shape, nil] shape object of given slot if exists, otherwise nil
    def get_managed_shape(slot)
      @slots[slot]
    end

    # Clear information about managed shapes and remove all slots.
    #
    # Note that this function doesn't remove managed (child) shapes from the parent box shape
    # (they are still its child shapes but aren't managed anymore).
    def clear_box
      @slots.clear
    end

    # Append given shape to the box at the last managed position.
    # @param [Shape] shape shape to append
    # @return [Boolean] true on success, otherwise false
    def append_to_box(shape)
      insert_to_box(@slots.size, shape)
    end

    # Insert given shape to the box at the given position.
    # The given shape is inserted before the existing item at index 'slot', thus insert_to_box(0, something)
    # will insert an item in such way that it will become the first box element. Any occupied slots at given
    # position or beyond will be shifted to the next position.
    # @param [Integer] slot slot index for inserted shape
    # @param [Shape] shape shape to insert
    # @return [Boolean] true on success, otherwise false
    def insert_to_box(slot, shape)
      if shape && shape.is_a?(Shape) && is_child_accepted(shape.class)
        # protect duplicated occurrences
        return false if @slots.index(shape)

        # protect unbounded index
        return false if slot > @slots.size

        # add the shape to the children list if necessary
        unless @child_shapes.include?(shape)
          if @diagram
            @diagram.reparent_shape(shape, self)
          else
            shape.set_parent_shape(self)
          end
        end

        @slots.insert(slot, shape)

        return true
      end
      false
    end

    # Remove given shape from the box.
    # Shifts any occupied cells beyond the slots containing the given shape to the previous position.
    # @param [Shape] shape shape which should be removed
    # @note Note this does *not* remove the shape as a child shape.
    def remove_from_box(shape)
      @slots.delete(shape)
    end

    # Update shape (align all child shapes and resize it to fit them)
    def update(recurse = true)
      # check for stale links to of de-assigned shapes
      @slots.delete_if do |shape|
        !@child_shapes.include?(shape)
      end

      # check whether all child shapes are present in the slots array...
      @child_shapes.each do |child|
        unless @slots.include?(child)
          # see if we can match the position of the new child with the position of another
          # (previously assigned) managed shape
          find_child_slot(child)
        end
      end

      # do self-alignment
      do_alignment

      # fit the shape to its children
      fit_to_children unless has_style?(STYLE::NO_FIT_TO_CHILDREN)

      # do it recursively on all parent shapes
      if recurse && (parent = get_parent_shape)
        parent.update(recurse)
      end
    end

    # Resize the shape to bound all child shapes. The function can be overridden if necessary.
    def fit_to_children
      # get bounding box of the shape and children set to be inside it
      abs_pos = get_absolute_position
      ch_bb = Wx::Rect.new(abs_pos.to_point, [0, 0])

      @child_shapes.each do |child|
        child.get_complete_bounding_box(ch_bb, BBMODE::SELF | BBMODE::CHILDREN) if child.has_style?(STYLE::ALWAYS_INSIDE)
      end

      if @child_shapes.empty?
        # do not let the empty box shape 'disappear' due to zero sizes...
        ch_bb.set_width(BoxShape.min_size.width) if (ch_bb.width + 2*@spacing) <= BoxShape.min_size.width && get_h_align != HALIGN::EXPAND
        ch_bb.set_height(BoxShape.min_size.height) if (ch_bb.height + 2*@spacing) <= BoxShape.min_size.height && get_v_align != VALIGN::EXPAND
      end

      @rect_size = Wx::RealPoint.new(ch_bb.width + 2*@spacing, ch_bb.height + 2*@spacing)
    end

    # Event handler called when any shape is dropped above this shape (and the dropped
    # shape is accepted as a child of this shape). The function can be overridden if necessary.
    #
    # The function is called by the framework (by the shape canvas).
    # @param [Wx::RealPoint] _pos Relative position of dropped shape
    # @param [Shape] child dropped shape
    def on_child_dropped(_pos, child)
      # see if we can match the position of the new child with the position of another
      # (previously assigned) managed shape
      if child && !child.is_a?(LineShape)
        # if the child already had a slot
        if @slots.index(child)
          # remove it from there; this provides support for reordering child shapes by dragging
          remove_from_box(child)
        end

        # insert child based on it's current (possibly dropped) position
        find_child_slot(child)
      end
    end

    protected

    # Do layout of assigned child shapes
    def do_children_layout
      return if @slots.empty?

      max_size = 0

      # get maximum size of all managed (child) shapes
      @child_shapes.each do |shape|
        curr_rect = shape.get_bounding_box
        curr_rect.inflate!(shape.h_border.abs.to_i, shape.v_border.abs.to_i)

        if @orientation == ORIENTATION::VERTICAL
          max_size = curr_rect.width if shape.get_h_align != HALIGN::EXPAND && curr_rect.width > max_size
        else
          max_size = curr_rect.height if shape.get_v_align != VALIGN::EXPAND && curr_rect.height > max_size
        end
      end

      # if this box itself is expanded for the appropriate dimension check the max child size against the box size
      if @orientation == ORIENTATION::VERTICAL && get_h_align == HALIGN::EXPAND
        box_rect = get_bounding_box
        # if this box is horizontally expanded use it's width if larger
        max_size = box_rect.width - 2*@spacing if (box_rect.width-2*@spacing) > max_size
      elsif @orientation == ORIENTATION::HORIZONTAL && get_v_align == VALIGN::EXPAND
        box_rect = get_bounding_box
        # if this box is vertically expanded use it's height if larger
        max_size = box_rect.height - 2*@spacing if (box_rect.height-2*@spacing) > max_size
      end

      offset = @spacing
      @slots.each do |shape|
        if @orientation == ORIENTATION::VERTICAL
          shape_h = shape.get_bounding_box.height + (2*shape.get_v_border).to_i
          fit_shape_to_rect(shape, Wx::Rect.new(@spacing,
                                                offset,
                                                max_size, shape_h))
          offset += shape_h+@spacing
        else
          shape_w = shape.get_bounding_box.width + (2*shape.get_h_border).to_i
          fit_shape_to_rect(shape, Wx::Rect.new(offset,
                                                @spacing,
                                                shape_w, max_size))
          offset += shape_w+@spacing
        end
      end
    end

    # called after the shape has been newly imported/pasted/dropped
    # checks the slots for stale links
    def on_import
      # check for existence of non-included shapes
      @slots.delete_if do |shape|
        !@child_shapes.include?(shape)
      end
    end

    def find_child_slot(child)
      crct = child.get_bounding_box
      # if the child intersects this box shape we look
      # for the slot it should go into
      if intersects?(crct)
        # find the slot with a shape that is positioned below/after
        # the new child
        slot = @slots.find_index do |shape|
          # determine if new child is positioned above/in front of existing child shape
          srct = shape.get_bounding_box
          if @orientation == ORIENTATION::VERTICAL
            crct.bottom <= srct.bottom || crct.top <= srct.top
          else
            crct.right <= srct.right || crct.left <= srct.left
          end
        end
        if slot # if found
          # insert before other shape
          @slots.insert(slot, child)
          return
        end
      end
      # otherwise append
      @slots << child
    end

    private

    # Deserialization only.

    # Set the orientation of the box shape.
    # @param [Wx::SF::BoxShape::ORIENTATION] orientation
    def set_orientation(orientation)
      @orientation = orientation
    end

    def get_slots
      @slots
    end
    def set_slots(slots)
      @slots = slots
    end

  end

  # Convenience class encapsulating a BoxShape with vertical orientation.
  class VBoxShape < BoxShape

    # Constructor.
    # @param [Wx::RealPoint,Wx::Point] pos Initial position
    # @param [Wx::RealPoint,Wx::Point,Wx::Size] size Initial size
    # @param [Integer] spacing Additional space between managed shapes
    # @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(pos = Shape::DEFAULT::POSITION, size = RectShape::DEFAULT::SIZE, spacing: DEFAULT::SPACING, diagram: nil)
      super(pos, size, orientation: ORIENTATION::VERTICAL, spacing: spacing, diagram: diagram)
    end

  end

  # Convenience class encapsulating a BoxShape with horizontal orientation.
  class HBoxShape < BoxShape

    # Constructor.
    # @param [Wx::RealPoint,Wx::Point] pos Initial position
    # @param [Wx::RealPoint,Wx::Point,Wx::Size] size Initial size
    # @param [Integer] spacing Additional space between managed shapes
    # @param [Wx::SF::Diagram] diagram parent diagram
    def initialize(pos = Shape::DEFAULT::POSITION, size = RectShape::DEFAULT::SIZE, spacing: DEFAULT::SPACING, diagram: nil)
      super(pos, size, orientation: ORIENTATION::HORIZONTAL, spacing: spacing, diagram: diagram)
    end

  end

end
