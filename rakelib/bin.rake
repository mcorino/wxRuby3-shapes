###
# wxRuby3Shapes rake file
# Copyright (c) M.J.N. Corino, The Netherlands
###

require 'rake/clean'

require_relative './bin'

directory 'bin'

file File.join('bin', 'wx-shapes') => 'bin' do |t|
  File.open(t.name, 'w') { |f| f.puts WXRuby3Shapes::Bin.wx_shapes }
  File.chmod(0755, t.name)
end

namespace :wxruby_shapes do

  namespace :bin do

    task :build => ['wxruby_shapes:bin:check', File.join('bin', 'wx-shapes')]

    task :check do
      WXRuby3Shapes::Bin.binaries.each do |bin|
        if File.exist?(File.join('bin', bin))
          content = IO.read(File.join('bin', bin))
          rm_f(File.join('bin', bin)) unless content == WXRuby3Shapes::Bin.__send__(bin.gsub(/[-\.]/,'_').to_sym)
        end
      end
    end
  end
end

CLOBBER.include File.join('bin', 'wx-shapes')

if WXRuby3Shapes::Config.windows?

  file File.join('bin', 'wx-shapes.bat') => ['bin'] do |t|
    File.open(t.name, 'w') { |f| f.puts WXRuby3Shapes::Bin.wx_shapes_bat }
  end
  Rake::Task['wxruby_shapes:bin:build'].enhance [File.join('bin', 'wx-shapes.bat')]

  CLOBBER.include File.join('bin', 'wx-shapes.bat')

end
