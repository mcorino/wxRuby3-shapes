# Wx::SF::CanvasHistory - canvas history class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  class CanvasHistory

    module DEFAULT
      MAX_CANVAS_STATES = 25
    end

    # Constructor.
    def initialize
      @canvas_states = []
      @current_state = nil
      @current_state_index = nil
      @max_states = DEFAULT::MAX_CANVAS_STATES
    end

    attr_accessor :max_states

    # Save current canvas state.
    # @param [String] state serialized diagram state
    def save_canvas_state(state)
      # delete all states newer than the current state
      if @current_state
        @canvas_states.slice!(@current_state_index+1, @canvas_states.size)
      end

      # append new canvas state
      @current_state_index = @canvas_states.size
      @canvas_states << (@current_state = state)

      # check the history bounds
      if @canvas_states.size > @max_states
        @canvas_states.shift
        @current_state_index -= 1
      end
    end

    # Perform the 'Undo' operation.
    # @returns [String] state to undo
    def restore_older_state
      return nil unless @current_state && @current_state_index>0

      # move to previous canvas state and restore
      @current_state_index -= 1
      @current_state = @canvas_states[@current_state_index]
    end

    # Perform the 'Redo' operation. 
    # @returns [String] state to redo
    def restore_newer_state
      return nil unless @current_state && @current_state_index<(@canvas_states.size-1)

      # move to next canvas state and restore
      @current_state_index += 1
      @current_state = @canvas_states[@current_state_index]
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
    # @return true if the 'redo' operation can be performed, otherwise false
    def can_redo
      @current_state && @current_state_index < (@canvas_states.size - 1)
    end

  end

end
