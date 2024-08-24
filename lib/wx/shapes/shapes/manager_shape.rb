# Wx::SF::ContainerShape - container shape mixin
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  # Mixin for container shape classes that control there child shape size/position/alignment.
  module ManagerShape

    # Returns true if the shape manages (size/position/alignment) of it's child shapes.
    # @return [Boolean] true
    def is_manager
      true
    end
    alias :manager? :is_manager

  end

end
