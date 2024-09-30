require 'wx/shapes'

module SerializerTestMixin

  def test_shape
    obj = Wx::SF::Shape.new
    obj.set_relative_position(Wx::RealPoint.new(100, 99))
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = FIRM.deserialize(obj_serial) }
    assert_instance_of(Wx::SF::Shape, obj_new)
    assert_equal(obj.get_relative_position, obj_new.get_relative_position)
  end

  def test_line_shape
    obj = Wx::SF::LineShape.new(Wx::RealPoint.new(100, 100), Wx::RealPoint.new(400, 400))
    obj.set_src_arrow(Wx::SF::SolidArrow)
    obj.set_trg_arrow(Wx::SF::SolidArrow)
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = FIRM.deserialize(obj_serial) }
    assert_instance_of(Wx::SF::LineShape, obj_new)
    assert_equal(obj.get_src_point, obj_new.get_src_point)
    assert_equal(obj.get_trg_point, obj_new.get_trg_point)
    assert_instance_of(Wx::SF::SolidArrow, obj_new.get_src_arrow)
    assert_equal(obj_new.object_id, obj_new.get_src_arrow.get_parent_shape.object_id)
    assert_instance_of(Wx::SF::SolidArrow, obj_new.get_trg_arrow)
    assert_equal(obj_new.object_id, obj_new.get_trg_arrow.get_parent_shape.object_id)
  end

  def test_rect_shape
    obj = Wx::SF::RectShape.new
    obj.set_relative_position(Wx::RealPoint.new(100, 99))
    obj.set_rect_size(20.0, 20.0)
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = FIRM.deserialize(obj_serial) }
    assert_instance_of(Wx::SF::RectShape, obj_new)
    assert_equal(obj.get_relative_position, obj_new.get_relative_position)
    assert_equal(Wx::RealPoint.new(20.0, 20.0), obj_new.get_rect_size)
  end

  def test_grid_shape
    obj = Wx::SF::GridShape.new
    obj.set_relative_position(Wx::RealPoint.new(100, 99))
    obj.set_rect_size(20.0, 20.0)
    obj.set_dimensions(2, 3)
    obj.accept_child(Wx::SF::RectShape)
    assert(obj.append_to_grid(Wx::SF::RectShape.new)) # should be cell 0,0
    assert(obj.insert_to_grid(1, 0, Wx::SF::RectShape.new)) # cell 1,0
    obj_serial = obj.serialize(pretty: true)
    obj_new = nil
    assert_nothing_raised { obj_new = FIRM.deserialize(obj_serial) }
    assert_instance_of(Wx::SF::GridShape, obj_new)
    assert_equal(obj.get_relative_position, obj_new.get_relative_position)
    assert_equal(Wx::RealPoint.new(20.0, 20.0), obj_new.get_rect_size)
    assert_instance_of(Wx::SF::RectShape, obj_new.get_managed_shape(0, 0))
    assert_nil(obj_new.get_managed_shape(0, 1))
    assert_nil(obj_new.get_managed_shape(0, 2))
    assert_instance_of(Wx::SF::RectShape, obj_new.get_managed_shape(1, 0))
    assert_nil(obj_new.get_managed_shape(1, 1))
    assert_nil(obj_new.get_managed_shape(1, 2))
  end

  def test_bitmap_shape
    obj = Wx::SF::BitmapShape.new
    assert(obj.create_from_file(:motyl, Wx::BitmapType::BITMAP_TYPE_BMP))
    obj.set_relative_position(Wx::RealPoint.new(100, 99))
    obj_serial = obj.serialize(pretty: true)
    obj_new = nil
    assert_nothing_raised { obj_new = FIRM.deserialize(obj_serial) }
    assert_instance_of(Wx::SF::BitmapShape, obj_new)
    assert_equal(obj.get_relative_position, obj_new.get_relative_position)
    assert(obj_new.instance_variable_get('@bitmap').ok?)
  end

  def test_canvas
    frame = Wx::Frame.new(nil)
    frame.set_size([800, 600])
    frame.client_rect
    canvas = Wx::SF::ShapeCanvas.new(Wx::SF::Diagram.new, frame)
    io = StringIO.new
    assert_nothing_raised { canvas.save_canvas(io, compact: false) }
    io.rewind
    assert_nothing_raised {  canvas.load_canvas(io) }
  end

end
