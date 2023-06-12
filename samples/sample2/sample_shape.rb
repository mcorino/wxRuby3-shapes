# Wx::SF - Sample2 SampleShape class
# Copyright (c) M.J.N. Corino, The Netherlands

require 'wx/shapes'

class SampleShape < Wx::SF::RectShape

  def initialize
    super
  end

  # override required wxSF virtual functions
	def on_left_click(pos)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::MouseEvent, "Called handler: 'on_left_click', Shape ID: #{get_id}, Position: #{pos}\n")

    # call original handler if required
    super
  end
	def on_right_click(pos)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::MouseEvent, "Called handler: 'on_right_click', Shape ID: #{get_id}, Position: #{pos}\n")

    # call original handler if required
    super
  end
	def on_left_double_click(pos)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::MouseEvent, "Called handler: 'on_left_double_click', Shape ID: #{get_id}, Position: #{pos}\n")

    # call original handler if required
    super
  end
	def on_right_double_click(pos)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::MouseEvent, "Called handler: 'on_right_double_click', Shape ID: #{get_id}, Position: #{pos}\n")

    # call original handler if required
    super
  end

	def on_begin_drag(pos)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::MouseEvent, "Called handler: 'on_begin_drag', Shape ID: #{get_id}, Position: #{pos}\n")

    # call original handler if required
    super
  end
	def on_dragging(pos)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::MouseEvent, "Called handler: 'on_dragging', Shape ID: #{get_id}, Position: #{pos}\n")

    # call original handler if required
    super
  end
	def on_end_drag(pos)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::MouseEvent, "Called handler: 'on_end_drag', Shape ID: #{get_id}, Position: #{pos}\n")

    # call original handler if required
    super
  end

	def on_begin_handle(handle)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::HandleEvent, "Called handler: 'on_begin_handle()', Shape ID: #{get_id}, Handle type: #{handle.type}\n")

    # call original handler if required
    super
  end
	def on_handle(handle)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::HandleEvent, "Called handler: 'on_handle()', Shape ID: #{get_id}, Handle type: #{handle.type}\n")

    # call original handler if required
    super
  end
	def on_end_handle(handle)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::HandleEvent, "Called handler: 'on_end_handle()', Shape ID: #{get_id}, Handle type: #{handle.type}\n")

    # call original handler if required
    super
  end

	def on_mouse_enter(pos)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::MouseEvent, "Called handler: 'on_mouse_enter', Shape ID: #{get_id}, Position: #{pos}\n")

    # call original handler if required
    super
  end
	def on_mouse_over(pos)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::MouseEvent, "Called handler: 'on_mouse_over', Shape ID: #{get_id}, Position: #{pos}\n")

    # call original handler if required
    super
  end
	def on_mouse_leave(pos)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::MouseEvent, "Called handler: 'on_mouse_leave', Shape ID: #{get_id}, Position: #{pos}\n")

    # call original handler if required
    super
  end

  def on_key(key)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::KeyEvent, "Called handler: 'on_key()', Shape ID: #{get_id}, Key code: #{key}\n")

    # call original handler if required
    super
  end

	def on_child_dropped(pos, child)
    SFSample2Frame.log(SFSample2Frame::LOGTYPE::ChildDropEvent, "Called handler: 'on_child_dropped()', Parent shape ID: #{get_id}, Child shape ID: #{child.get_id}\n")

    # call original handler if required
    super
  end
end
