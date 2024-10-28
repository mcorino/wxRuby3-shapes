
require_relative './lib/wxapp_runner'
require 'wx/shapes'

class GridShapeTests < Test::Unit::TestCase

  def test_grid_shape
    obj = Wx::SF::GridShape.new
    obj.set_relative_position(Wx::RealPoint.new(100, 99))
    obj.set_rect_size(20.0, 20.0)
    obj.set_dimensions(2, 3)
    obj.accept_child(Wx::SF::RectShape)
    assert(obj.append_to_grid(Wx::SF::RectShape.new)) # should be cell 0,0
    assert(obj.insert_to_grid(1, 0, Wx::SF::RectShape.new)) # cell 1,0
    assert_instance_of(Wx::SF::RectShape, obj.get_managed_shape(0, 0))
    assert_nil(obj.get_managed_shape(0, 1))
    assert_nil(obj.get_managed_shape(0, 2))
    assert_instance_of(Wx::SF::RectShape, obj.get_managed_shape(1, 0))
    assert_nil(obj.get_managed_shape(1, 1))
    assert_nil(obj.get_managed_shape(1, 2))
    assert_nothing_raised { obj.update }
  end

  def test_flex_grid_shape
    obj = Wx::SF::FlexGridShape.new
    obj.set_relative_position(Wx::RealPoint.new(100, 99))
    obj.set_rect_size(20.0, 20.0)
    obj.set_dimensions(2, 3)
    obj.accept_child(Wx::SF::RectShape)
    assert(obj.append_to_grid(Wx::SF::RectShape.new)) # should be cell 0,0
    assert(obj.insert_to_grid(1, 0, Wx::SF::RectShape.new)) # cell 1,0
    assert_instance_of(Wx::SF::RectShape, obj.get_managed_shape(0, 0))
    assert_nil(obj.get_managed_shape(0, 1))
    assert_nil(obj.get_managed_shape(0, 2))
    assert_instance_of(Wx::SF::RectShape, obj.get_managed_shape(1, 0))
    assert_nil(obj.get_managed_shape(1, 1))
    assert_nil(obj.get_managed_shape(1, 2))
    assert_nothing_raised { obj.update }
  end


end
