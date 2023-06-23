# wx-shapes unit test command handler
# Copyright (c) M.J.N. Corino, The Netherlands
#--------------------------------------------------------------------

require 'fileutils'

module WxShapes
  module Commands
    class Test
      def self.description
        "    test\t\t\tRun wx/shapes regression tests."
      end

      def self.run(argv)
        if argv == :describe
          description
        else
          Dir[File.join(WxShapes::ROOT, 'tests', 'test_*.rb')].each do |test|
            system(RUBY, test)
          end
        end
      end
    end

    self.register('test', Test)
  end
end