###
# wxRuby3-shapes rake configuration
# Copyright (c) M.J.N. Corino, The Netherlands
###

require 'rbconfig'
require 'fileutils'

module FileUtils
  # add convenience methods
  def rmdir_if(list, **kwargs)
    list = fu_list(list).select { |path| File.exist?(path) }
    rmdir(list, **kwargs) unless list.empty?
  end
  def rm_if(list, **kwargs)
    list = fu_list(list).select { |path| File.exist?(path) }
    rm_f(list, **kwargs) unless list.empty?
  end
end

module WXRuby3Shapes
  ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

  if defined? ::RbConfig
    RB_CONFIG = ::RbConfig::CONFIG
  else
    RB_CONFIG = ::Config::CONFIG
  end unless defined? RB_CONFIG

  # Ruby 2.5 is the minimum version for wxRuby3-shapes
  __rb_ver = RUBY_VERSION.split('.').collect {|v| v.to_i}
  if (__rb_major = __rb_ver.shift) < 2 || (__rb_major == 2 && __rb_ver.shift < 5)
    STDERR.puts 'ERROR: wxRuby3-shapes requires Ruby >= 2.5.0!'
    exit(1)
  end

  # Pure-ruby lib files
  ALL_RUBY_LIB_FILES = FileList[ 'lib/**/*.rb' ]

  # The version file
  VERSION_FILE = File.join(ROOT,'lib', 'wx', 'shapes', 'version.rb')

  if File.exist?(VERSION_FILE)
    require VERSION_FILE
    WXSF_VERSION = Wx::SF::VERSION
    # Leave version undefined
  else
    WXSF_VERSION = ''
  end

  module Config

    def do_run(*cmd, capture: nil)
      output = nil
      if capture
        env_bup = exec_env.keys.inject({}) do |h, ev|
          h[ev] = ENV[ev] ? ENV[ev].dup : nil
          h
        end
        case capture
        when :out
          # default
        when :no_err
          # redirect stderr to null sink
          cmd << '2> ' << (windows? ? 'NULL' : '/dev/null')
        when :err, :all
          cmd << '2>&1'
        end
        begin
          # setup ENV for child execution
          ENV.merge!(Config.instance.exec_env)
          output = `#{cmd.join(' ')}`
        ensure
          # restore ENV
          env_bup.each_pair do |k,v|
            if v
              ENV[k] = v
            else
              ENV.delete(k)
            end
          end
        end
      else
        Rake.sh(exec_env, *cmd, verbose: verbose?)
      end
      output
    end
    private :do_run

    def make_ruby_cmd(*cmd, verbose: true)
      [
        FileUtils::RUBY,
        '-I', rb_lib_path,
        (verbose && verbose? ? '-v' : nil),
        *cmd.flatten
      ].compact
    end
    private :make_ruby_cmd

    def execute(*cmd)
      do_run(*cmd.flatten)
    end

    def run(*cmd, capture: nil, verbose: true)
      do_run(*make_ruby_cmd(cmd, verbose: verbose), capture: capture)
    end

    def respawn_rake(argv = ARGV)
      Kernel.exec($0, *argv)
    end

    def expand(cmd)
      `#{cmd}`
    end
    private :expand

    def sh(*cmd, **kwargs)
      Rake.sh(*cmd, **kwargs) { |ok,_| !!ok }
    end
    private :sh
    alias :bash :sh
    private :bash

    def test(*tests, **options)
      tests = Dir.glob(File.join(Config.instance.test_dir, '*.rb')) if tests.empty?
      tests.each do |test|
        unless File.exist?(test)
          test = File.join(Config.instance.test_dir, test)
          test = Dir.glob(test+'.rb').shift || test unless File.exist?(test)
        end
        Rake.sh(Config.instance.exec_env, *make_ruby_cmd(test))
      end
    end

    def irb(**options)
      irb_cmd = File.join(File.dirname(FileUtils::RUBY), 'irb')
      Rake.sh(Config.instance.exec_env, *make_ruby_cmd('-x', irb_cmd), **options)
    end

    class << self

      def rb_version
        @rb_version ||= RUBY_VERSION.split('.').collect {|n| n.to_i}
      end

      def rb_ver_major
        rb_version[0]
      end

      def rb_ver_minor
        rb_version[1]
      end

      def rb_ver_release
        rb_version[2]
      end

      def wxruby_root
        WXRuby3::ROOT
      end

      def platform
        case RUBY_PLATFORM
        when /mingw/
          :mingw
        when /cygwin/
          :cygwin
        when /netbsd/
          :netbsd
        when /darwin/
          :macosx
        when /linux/
          :linux
        else
          :unknown
        end
      end

      def cygwin?
        platform == :cygwin
      end

      def mingw?
        platform == :mingw
      end

      def netbsd?
        platform == :netbsd
      end

      def macosx?
        platform == :macosx
      end

      def linux?
        platform == :linux
      end

      def windows?
        mingw? || cygwin?
      end

    end # class << self

  end # module Config

end # module WXRuby3Shapes

# Dir.glob(File.join(File.dirname(__FILE__), 'ext', '*.rb')).each do |fn|
#   require fn
# end
