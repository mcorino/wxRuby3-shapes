###
# wxRuby3Shapes rake file
# Copyright (c) M.J.N. Corino, The Netherlands
###

require 'rake/packagetask'

Rake::PackageTask.new("wxruby3-shapes", WXRuby3Shapes::WXSF_VERSION) do |p|
  p.need_tar_gz = true
  p.need_zip = true
  p.package_files.include(%w{assets/**/* samples/**/* lib/**/* tests/**/* rakelib/**/*})
  p.package_files.include(%w{INSTALL* LICENSE* Gemfile rakefile README.md CREDITS.md .yardopts})
end
