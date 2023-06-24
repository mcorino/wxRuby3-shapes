# wx-shapes unit test command handler
# Copyright (c) M.J.N. Corino, The Netherlands
#--------------------------------------------------------------------

require 'fileutils'

module WxShapes
  module Commands
    class Test
      def self.description
        "    test\t\t\tRun wxRuby3/Shapes regression tests."
      end

      def self.run(argv)
        if argv == :describe
          description
        else
          Dir[File.join(WxShapes::ROOT, 'tests', 'test_*.rb')].each do |test|
            exit(1) unless system(RUBY, test)
          end
        end
      end
    end

    self.register('test', Test)
  end
end
