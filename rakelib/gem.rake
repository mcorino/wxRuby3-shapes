###
# wxRuby3Shapes rake file
# Copyright (c) M.J.N. Corino, The Netherlands
###

require_relative './gem'

namespace :wxruby_shapes do

  task :gem => ['bin:build', WXRuby3Shapes::Gem.gem_file('wxruby3-shapes', WXRuby3Shapes::WXSF_VERSION)]

end

# source gem file
file WXRuby3Shapes::Gem.gem_file('wxruby3-shapes', WXRuby3Shapes::WXSF_VERSION) => WXRuby3Shapes::Gem.manifest do
  gemspec = WXRuby3Shapes::Gem.define_spec('wxruby3-shapes', WXRuby3Shapes::WXSF_VERSION) do |gem|
    gem.summary = %Q{wxRuby3 2D shapes and diagramming framework}
    gem.description = %Q{wxRuby3/Shapes is a pure Ruby library providing 2D shapes and diagramming framework based on wxRuby3}
    gem.email = 'mcorino@m2c-software.nl'
    gem.homepage = "https://github.com/mcorino/wxRuby3-shapes"
    gem.authors = ['Martin Corino']
    gem.files = WXRuby3Shapes::Gem.manifest
    gem.require_paths = %w{lib}
    gem.bindir = 'bin'
    gem.executables = WXRuby3Shapes::Bin.binaries
    gem.required_ruby_version = '>= 2.5'
    gem.licenses = ['MIT']
    gem.add_dependency 'rake'
    gem.add_dependency 'minitest', '~> 5.15'
    gem.add_dependency 'test-unit', '~> 3.5'
    gem.add_dependency 'nokogiri', '~> 1.12'
    gem.add_dependency 'firm', '~> 1.0'
    gem.add_dependency 'wxruby3', '~> 1.3'
    gem.add_dependency 'wxruby3-mdap', '~> 1.0'
    gem.metadata = {
      "bug_tracker_uri"   => "https://github.com/mcorino/wxRuby3-shapes/issues",
      "source_code_uri"   => "https://github.com/mcorino/wxRuby3-shapes",
      "documentation_uri" => "https://mcorino.github.io/wxRuby3-shapes",
      "homepage_uri"      => "https://github.com/mcorino/wxRuby3-shapes",
    }
    gem.post_install_message = <<~__MSG

      wxRuby3/Shapes has been successfully installed including the 'wx-shapes' utility.

      You can run the regression tests to verify the installation by executing:

      $ ./wx-shapes test

      The wxRuby3/Shapes samples can be run by executing:

      $ ./wx-shapes sampler <sample>

      Where sample is 'sample1', 'sample2', 'sample3', 'sample4' or 'demo'.

      Have fun using wxRuby3/Shapes.
      __MSG
  end
  WXRuby3Shapes::Gem.build_gem(gemspec)
end

desc 'Build wxruby3-shapes gem'
task :gem => 'wxruby_shapes:gem'
