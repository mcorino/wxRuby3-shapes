require 'wx/shapes'

module SerializerTestMixin

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

    obj = Struct.new('MyStruct', :one, :two).new(one: Wx::Point.new(10, 90), two: Wx::Point.new(20, 80))
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
      @fixed_item.disable_list_serialize
      self.list << @fixed_item
    end

  end

  class SerializedDerived2_1 < SerializedBase2
    property :extra_item

    def initialize(list = [], extra = nil)
      super(list)
      set_extra_item(extra)
    end

    attr_reader :extra_item

    def set_extra_item(extra)
      @extra_item = extra
      if @extra_item
        @extra_item.disable_list_serialize
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
      @fixed_item.disable_list_serialize
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

end
