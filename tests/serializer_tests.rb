require 'wx/shapes'

module SerializerTestMixin

  class PropTest

    include Wx::SF::Serializable

    property :prop_a
    property prop_b: ->(obj, *val) { obj.instance_variable_set(:@prop_b, val.first) unless val.empty?; obj.instance_variable_get(:@prop_b) }
    property prop_c: :serialize_prop_c
    property(:prop_d, :prop_e) do |id, obj, *val|
      case id
      when :prop_d
        obj.instance_variable_set('@prop_d', val.first) unless val.empty?
        obj.instance_variable_get('@prop_d')
      when :prop_e
        obj.instance_variable_set('@prop_e', val.first) unless val.empty?
        obj.instance_variable_get('@prop_e')
      end
    end
    property :prop_f, :prop_g, handler: :serialize_props_f_and_g

    def initialize
      @prop_a = 'string'
      @prop_b = 123
      @prop_c = :symbol
      @prop_d = 100.123
      @prop_e = [1,2,3]
      @prop_f = {_1: 1, _2: 2, _3: 3}
      @prop_g = 1..10
    end

    attr_accessor :prop_a

    def serialize_prop_c(*val)
      @prop_c = val.first unless val.empty?
      @prop_c
    end
    private :serialize_prop_c

    def serialize_props_f_and_g(id, *val)
      case id
      when :prop_f
        @prop_f = val.shift unless val.empty?
        @prop_f
      when :prop_g
        @prop_g = val.shift unless val.empty?
        @prop_g
      end
    end

    def ==(other)
      self.class === other &&
        @prop_a == other.prop_a &&
        @prop_b == other.instance_variable_get('@prop_b') &&
        @prop_c == other.instance_variable_get('@prop_c') &&
        @prop_d == other.instance_variable_get('@prop_d') &&
        @prop_e == other.instance_variable_get('@prop_e') &&
        @prop_g == other.instance_variable_get('@prop_g') &&
        @prop_f == other.instance_variable_get('@prop_f')
    end
  end

  def test_properties
    obj = PropTest.new
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(PropTest, obj_new)
    assert_equal(obj, obj_new)
  end

  def test_wx_data
    obj = Wx::Point.new(10, 90)
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(Wx::Point, obj_new)
    assert_equal(obj, obj_new)

    obj = Wx::RealPoint.new(10, 90)
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(Wx::RealPoint, obj_new)
    assert_equal(obj, obj_new)

    obj = Wx::Size.new(100, 900)
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(Wx::Size, obj_new)
    assert_equal(obj, obj_new)

    obj = Wx::Rect.new(10, 20, 100, 900)
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(Wx::Rect, obj_new)
    assert_equal(obj, obj_new)

    obj = Wx::Colour.new('red')
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(Wx::Colour, obj_new)
    assert_equal(obj, obj_new)

    obj = Wx::Pen.new('black')
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(Wx::Pen, obj_new)
    assert_equal(obj, obj_new)
  end

  def test_core
    obj = [Wx::Point.new(10, 90), Wx::Point.new(20, 80)]
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)

    obj = { '1' => Wx::Point.new(10, 90), '2' => Wx::Point.new(20, 80) }
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)

    Struct.new('MyStruct', :one, :two) unless defined? Struct::MyStruct
    obj = Struct::MyStruct.new(one: Wx::Point.new(10, 90), two: Wx::Point.new(20, 80))
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)

    obj = ::Set.new(%i[one two three])
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)

    obj = OpenStruct.new(one: Wx::Point.new(10, 90), two: Wx::Point.new(20, 80))
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)

    obj = [1, nil, 2]
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)
  end

  class PointsOwner
    include Wx::SF::Serializable

    property :points

    def initialize(points = [])
      @points = points
    end

    attr_accessor :points

    def ==(other)
      self.class === other && @points == other.points
    end
  end

  def test_composition
    obj = PointsOwner.new([Wx::Point.new(10, 90), Wx::Point.new(20, 80)])
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)
  end

  def test_connection_point
    obj = Wx::SF::ConnectionPoint.new(nil, Wx::SF::ConnectionPoint::CPTYPE::TOPLEFT)
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(obj.class, obj_new)
    assert_equal(obj.type, obj_new.type)
    assert_equal(obj.relative_position, obj_new.relative_position)
    assert_equal(obj.ortho_direction, obj_new.ortho_direction)
  end

  class SerializedBase
    include Wx::SF::Serializable

    property :a
    property :b
    property :c

    def initialize(a=nil, b=nil, c=nil)
      @a = a
      @b = b
      @c = c
    end

    attr_accessor :a, :b, :c

    def ==(other)
      self.class === other && self.a == other.a && self.b == other.b && self.c == other.c
    end
  end

  class SerializedDerived < SerializedBase
    contains :d
    excludes :c

    def initialize(a=nil, b=nil, d=nil)
      super(a, b)
      @d = d
      self.c = 'FIXED'
    end

    attr_accessor :d

    def ==(other)
      super && self.d == other.d
    end
  end

  def test_exclusion
    obj = SerializedBase.new(1, :hello, 'World')
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)

    obj = SerializedDerived.new(2, :derived, 103.50)
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)
  end

  class SerializedBase2
    include Wx::SF::Serializable

    property :list

    def initialize(list = [])
      @list = list
    end

    attr_reader :list

    def set_list(list)
      @list.insert(0, *(list || []))
    end
    private :set_list

    def ==(other)
      self.class === other && self.list == other.list
    end
  end

  class SerializedDerived2 < SerializedBase2

    def initialize(list = [])
      super
      @fixed_item = Wx::Point.new(30, 30)
      @fixed_item.disable_serialize
      self.list << @fixed_item
    end

  end

  class SerializedDerived2_1 < SerializedBase2
    property :extra_item, force: true

    def initialize(list = [], extra = nil)
      super(list)
      set_extra_item(extra)
    end

    attr_reader :extra_item

    def set_extra_item(extra)
      @extra_item = extra
      if @extra_item
        @extra_item.disable_serialize
        list << @extra_item
      end
    end
    private :set_extra_item

    def ==(other)
      super(other) && @extra_item == other.extra_item
    end
  end

  class SerializedBase3
    include Wx::SF::Serializable

    property :list

    def initialize(list = ::Set.new)
      @list = ::Set === list ? list : ::Set.new(list)
    end

    attr_reader :list

    def set_list(list)
      @list.merge(list || [])
    end
    private :set_list

    def ==(other)
      self.class === other && self.list == other.list
    end
  end

  class SerializedDerived3 < SerializedBase3

    def initialize(list = [])
      super
      @fixed_item = Wx::Point.new(30, 30)
      @fixed_item.disable_serialize
      self.list << @fixed_item
    end

  end

  def test_disable
    obj = SerializedBase2.new([Wx::Point.new(1,1), Wx::Point.new(2,2), Wx::Point.new(3,3)])
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)

    obj = SerializedDerived2.new([Wx::Point.new(1,1), Wx::Point.new(2,2), Wx::Point.new(3,3)])
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)

    obj = SerializedDerived2_1.new([Wx::Point.new(1,1), Wx::Point.new(2,2), Wx::Point.new(3,3)], Wx::Size.new(40, 40))
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)

    obj = SerializedDerived3.new([Wx::Point.new(1,1), Wx::Point.new(2,2), Wx::Point.new(3,3)])
    obj_serial = obj.serialize
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_equal(obj, obj_new)
  end

  class Identifiable
    include Wx::SF::Serializable

    property :id, :sym

    def initialize(sym = nil)
      @id = sym ? Wx::SF::Serializable::ID.new : nil
      @sym = sym
    end

    attr_accessor :sym
    attr_reader :id

    def set_id(id)
      @id = id
    end
    private :set_id
  end

  class Container
    include Wx::SF::Serializable

    property :map

    def initialize(map = {})
      @map = map
    end

    attr_reader :map

    def set_map(map)
      @map.replace(map)
    end
    private :set_map
  end

  class RefUser
    include Wx::SF::Serializable

    property :ref1, :ref2, :ref3

    def initialize(*rids)
      @ref1, @ref2, @ref3 = *rids
    end

    attr_accessor :ref1, :ref2, :ref3
  end

  def test_ids
    container = Container.new
    id_obj = Identifiable.new(:one)
    container.map[id_obj.id] = id_obj
    id_obj = Identifiable.new(:two)
    container.map[id_obj.id] = id_obj
    id_obj = Identifiable.new(:three)
    container.map[id_obj.id] = id_obj
    ref_obj = RefUser.new(*container.map.keys)
    obj_serial = [container, ref_obj].serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(Array, obj_new)
    assert_instance_of(Container, obj_new.first)
    assert_instance_of(RefUser, obj_new.last)
    assert_instance_of(Wx::SF::Serializable::ID, obj_new.last.ref1)
    assert_instance_of(Wx::SF::Serializable::ID, obj_new.last.ref2)
    assert_instance_of(Wx::SF::Serializable::ID, obj_new.last.ref3)
    assert_equal(:one, obj_new.first.map[obj_new.last.ref1].sym)
    assert_equal(:two, obj_new.first.map[obj_new.last.ref2].sym)
    assert_equal(:three, obj_new.first.map[obj_new.last.ref3].sym)
  end

  def test_nested_hash_with_complex_keys
    id_obj = Identifiable.new(:one)
    id_obj2 = Identifiable.new(:two)
    h = {
      [
        { id_obj.id => id_obj }
      ] => 'one',
      [
        { id_obj2.id => id_obj2 }
      ] => 'two'
    }
    obj_serial = h.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(::Hash, obj_new)
    obj_new.each_pair do |k,v|
      assert_instance_of(::Array, k)
      assert_instance_of(::String, v)
      assert_instance_of(::Hash, k.first)
      assert_instance_of(Wx::SF::Serializable::ID, k.first.first.first)
      assert_equal(v, k.first[k.first.first.first].sym.to_s)
    end
  end

  def test_shape
    obj = Wx::SF::Shape.new
    obj.set_relative_position(Wx::RealPoint.new(100, 99))
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(Wx::SF::Shape, obj_new)
    assert_equal(obj.get_relative_position, obj_new.get_relative_position)
  end

  def test_line_shape
    obj = Wx::SF::LineShape.new(Wx::RealPoint.new(100, 100), Wx::RealPoint.new(400, 400))
    obj.set_src_arrow(Wx::SF::SolidArrow)
    obj.set_trg_arrow(Wx::SF::SolidArrow)
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
    assert_instance_of(Wx::SF::LineShape, obj_new)
    assert_equal(obj.get_src_point, obj_new.get_src_point)
    assert_equal(obj.get_trg_point, obj_new.get_trg_point)
    assert_instance_of(Wx::SF::SolidArrow, obj_new.get_src_arrow)
    assert_equal(obj_new.id, obj_new.get_src_arrow.get_parent_shape.id)
    assert_instance_of(Wx::SF::SolidArrow, obj_new.get_trg_arrow)
    assert_equal(obj_new.id, obj_new.get_trg_arrow.get_parent_shape.id)
  end

  def test_rect_shape
    obj = Wx::SF::RectShape.new
    obj.set_relative_position(Wx::RealPoint.new(100, 99))
    obj.set_rect_size(20.0, 20.0)
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
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
    obj_serial = obj.serialize
    obj_new = nil
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
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
    assert_nothing_raised { obj_new = Wx::SF::Serializable.deserialize(obj_serial) }
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
