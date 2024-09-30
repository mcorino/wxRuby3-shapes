# Wx::SF - shape serializer module
# Copyright (c) M.J.N. Corino, The Netherlands

require 'firm'

Dir[File.join(__dir__, 'serialize', '*.rb')].each { |fnm| require "wx/shapes/serialize/#{File.basename(fnm)}" }
