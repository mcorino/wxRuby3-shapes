###
# wxRuby3-shapes rake file
# Copyright (c) M.J.N. Corino, The Netherlands
###

module WXRuby3Shapes
  HELP = <<__HELP_TXT

wxRuby3-shapes Rake based build system
--------------------------------------

This build system provides commands for testing and installing wxRuby3-shapes.

commands:

rake <rake-options> help             # Provide help description about wxRuby3-shapes build system
rake <rake-options> gem              # Build wxruby3-shapes gem
rake <rake-options> test             # Run all wxRuby3-shapes tests
rake <rake-options> package          # Build all the packages
rake <rake-options> repackage        # Force a rebuild of the package files
rake <rake-options> clobber_package  # Remove package products

__HELP_TXT
end

namespace :wxruby_shapes do
  task :help do
    puts WXRuby3Shapes::HELP
  end
end

desc 'Provide help description about wxRuby3-shapes build system'
task :help => 'wxruby_shapes:help'
