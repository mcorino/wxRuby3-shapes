
require_relative './lib/wxapp_runner'
require_relative './serializer_tests'

class SerializeTests < Test::Unit::TestCase
  include SerializerTestMixin
end
