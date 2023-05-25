# Wx::SF::CanvasHistory - canvas history class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  class CanvasHistory

    module DEFAULT
      MAX_CANVAS_STATES = 25
    end

    # @overload initialize()
    #   Default constructor.
    # @overload initialize(canvas)
    #   User constructor.
    #   @param [Wx::SF::ShapeCanvas] canvas managed canvas
    def initialize(canvas)
      @shape_canvas = canvas
      @canvas_states = []
      @current_state = nil
      @current_state_index = nil
      @max_states = DEFAULT::MAX_CANVAS_STATES
    end

    attr_accessor :max_states

    # Set pointer to the parent shapes canvas. All Undo/Redo operation defined by this class
    # will be performed on this shape canvas instance.
    # @param [Wx::SF::ShapeCanvas] canvas parent shape canvas
    def set_parent_canvas(canvas)
      @shape_canvas = canvas
    end
    alias :parent_canvas= :set_parent_canvas

    # Save current canvas state. 
    def save_canvas_state
      return unless @shape_canvas.get_diagram

      # serialize canvas
      state = @shape_canvas.get_diagram.serialize

      # delete all states newer than the current state
      if @current_state
        @canvas_states.slice!(@current_state_index+1, @canvas_states.size)
      end

      # append new canvas state
      @current_state_index = @canvas_states.size
      @canvas_states << (@current_state = state)

      # check the history bounds
      @canvas_states.shift if @canvas_states.size > @max_states
    end

    # Perform the 'Undo' operation. 
    def restore_older_state
      return unless @current_state && @current_state_index>0

      # move to previous canvas state and restore
      @current_state_index -= 1
      @current_state = @canvas_states[@current_state_index]
      @shape_canvas.set_diagram(Wx::SF::Diagram.deserialize(@current_state))
      @shape_canvas.diagram.set_modified
      @shape_canvas.refresh(false)
    end

    # Perform the 'Redo' operation. 
    def restore_newer_state
      return unless @current_state && @current_state_index<(@canvas_states.size-1)

      # move to next canvas state and restore
      @current_state_index += 1
      @current_state = @canvas_states[@current_state_index]
      @shape_canvas.set_diagram(Wx::SF::Diagram.deserialize(@current_state))
      @shape_canvas.diagram.set_modified
      @shape_canvas.refresh(false)
    end

    # Clear all canvas history. 
    def clear
      @canvas_states.clear
      @current_state = nil
      @current_state_index = nil
    end

    # The function gives information whether the 'Undo' operation is available
    # (exists any stored canvas state older than the current one.
    # @return [Boolean] true if the 'undo' operation can be performed, otherwise false
    def can_undo
      @current_state && @current_state_index>0
    end

    # The function gives information whether the 'redo' operation is available
    # (exists any stored canvas state newer than the current one.
    # @return true if the 'Undo' operation can be performed, otherwise false
    def can_redo
      @current_state && @current_state_index < (@canvas_states.size - 1)
    end

  end

end
