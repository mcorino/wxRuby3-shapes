# Wx::SF::ShapeCanvas - shape canvas class
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  class ShapeCanvas

    # Working modes 
    class MODE < Wx::Enum
      # The shape canvas is in ready state (no operation is pending)
      READY = self.new(0)
      # Some shape handle is dragged
      HANDLEMOVE = self.new(1)
      # Handle of multiselection tool is dragged
      MULTIHANDLEMOVE = self.new(2)
      # Some shape/s is/are dragged
		  SHAPEMOVE = self.new(3)
		  # Multiple shape selection is in progress
		  MULTISELECTION = self.new(4)
		  # Interactive connection creation is in progress
		  CREATECONNECTION = self.new(5)
		  # Canvas is in the Drag&Drop mode
		  DND = self.new(6)
	  end
  end

  # Selection modes 
  class SELECTIONMODE < Wx::Enum
    NORMAL = self.new(0)
    ADD = self.new(1)
    REMOVE = self.new(2)
  end

  # Search mode flags for GetShapeAtPosition function 
  class SEARCHMODE < Wx::Enum
    # Search for selected shapes only
    SELECTED = self.new(0)
    # Search for unselected shapes only
    UNSELECTED = self.new(1)
    # Search for both selected and unselected shapes
    BOTH = self.new(2)
  end

  # Flags for AlignSelected function 
  class VALIGN < Wx::Enum
    NONE = self.new(0)
    TOP = self.new(1)
    MIDDLE = self.new(2)
    BOTTOM = self.new(3)
  end

  # Flags for AlignSelected function 
  class HALIGN < Wx::Enum
    NONE = self.new(0)
    LEFT = self.new(1)
    CENTER = self.new(2)
    RIGHT = self.new(3)
  end

  # Style flags 
  class STYLE < Wx::Enum
    # Allow multiselection box. 
    MULTI_SELECTION = self.new(1)
    # Allow shapes' size change done via the multiselection box. 
    MULTI_SIZE_CHANGE = self.new(2)
    # Show grid. 
    GRID_SHOW = self.new(4)
    # Use grid. 
    GRID_USE = self.new(8)
    # Enable Drag & Drop operations. 
    DND = self.new(16)
    # Enable Undo/Redo operations. 
    UNDOREDO = self.new(32)
    # Enable the clipboard. 
    CLIPBOARD = self.new(64)
    # Enable mouse hovering 
    HOVERING = self.new(128)
    # Enable highlighting of shapes able to accept dragged shape(s).
    HIGHLIGHTING = self.new(256)
    # Use gradient color for the canvas background. 
    GRADIENT_BACKGROUND = self.new(512)
    # Print also canvas background. 
    PRINT_BACKGROUND = self.new(1024)
    # Process mouse wheel by the canvas (canvas scale will be changed). 
    PROCESS_MOUSEWHEEL = self.new(2048)
    # Default canvas style. 
    DEFAULT_CANVAS_STYLE = MULTI_SELECTION | MULTI_SIZE_CHANGE | DND | UNDOREDO | CLIPBOARD | HOVERING | HIGHLIGHTING
  end

end
