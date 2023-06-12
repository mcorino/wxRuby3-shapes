# Wx::SF - Sample2 SampleCanvas class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes'

class SampleCanvas < Wx::SF::ShapeCanvas
  def initialize(diagram, parent)
    super
	  add_style(STYLE::GRID_SHOW)
    add_style(STYLE::GRID_USE)
  end

  # override required wxSF virtual functions
  def on_left_down(event)
    # HINT: perform your user actions here...

    # perform standard operations
    super
  end

  def on_right_down(event)
    # HINT: perform your user actions here...

    # add new custom shape to the diagram ...
    _, shape = get_diagram.create_shape(SampleShape, event.get_position)
    # set some shape's properties...
    if shape
        # set accepted child shapes for the new shape
        shape.accept_child(SampleShape)
    end

    # perform standard operations
    super
  end
end
