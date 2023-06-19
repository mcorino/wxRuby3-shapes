# wx-shapes sampler command handler
# Copyright (c) M.J.N. Corino, The Netherlands
#--------------------------------------------------------------------

require 'fileutils'

module WxShapes
  module Commands
    class Sampler
      OPTIONS = {
        save_path: nil
      }

      def self.description
        "    sampler help|[SAMPLE [copy PATH]]\tRun wx/shapes sample application (or copy sample)."
      end

      def self.run(argv)
        if argv == :describe
          description
        else
          arg = argv.shift || 'demo'
          if arg == 'help'
            puts "Usage: wx-shapes [global options] sampler help|[SAMPLE [copy PATH]]\n\n" +
                 "\twhere SAMPLE := optional name of the sample to run or copy (sample1/2/3/4 or demo; default is 'demo')\n" +
                 "\t      PATH := optional path to copy sample to"
          else
            if arg != 'copy'
              sample = arg
              arg = argv.shift
            else
              sample = 'demo'
            end
            sample_dir = File.join(WxShapes::ROOT, 'samples', sample)
            unless File.directory?(sample_dir)
              STDERR.puts "ERROR: Unknown sample #{sample}"
              exit(1)
            end
            if arg == 'copy'
              dest = argv.shift
              unless dest && File.directory?(dest)
                STDERR.puts "ERROR: Invalid destination folder #{dest}"
                exit(1)
              end
              Dir[File.join(sample_dir, '*')].each do |fp|
                FileUtils.cp_r(fp, dest, verbose: true)
              end
            else
              exec(RUBY, File.join(sample_dir, sample.gsub(/\d+/, '')+'.rb'))
            end
          end
        end
      end
    end

    self.register('sampler', Sampler)
  end
end
