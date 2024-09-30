
require_relative './lib/wxapp_runner'
require_relative './serializer_tests'

class XMLSerializeTests < Test::Unit::TestCase

  include SerializerTestMixin

  def self.startup
    FIRM::Serializable.default_format = :xml
  end

  def self.shutdown
    FIRM::Serializable.default_format = nil
  end

end
