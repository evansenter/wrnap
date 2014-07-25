require "yaml"
require "benchmark"
require "set"
require "tree"
require "shuffle"
require "rinruby"
require "tempfile"
require "bigdecimal"
require "rroc"
require "bio"
require "bio-stockholm"
require "entrez"
require "active_support/inflector"
require "active_support/core_ext/class"

require "wrnap/version"

%w|global rna etl graphing|.each do |subfolder|
  Dir[File.join(File.dirname(__FILE__), "wrnap", subfolder, "*.rb")].each do |file|
    require file
  end
end

require "wrnap/rna"
require "wrnap/package/base"

# RinRuby is really finnicky.
begin; R.quit; rescue IOError; end

module Wrnap
  RT     = 1e-3 * 1.9872041 * (273.15 + 37) # kcal / K / mol @ 37C
  @debug = true

  module Package
    Dir[File.join(File.dirname(__FILE__), "wrnap", "package", "*.rb")].reject { |file| file =~ /\/base.rb$/ }.each do |file|
      autoload(File.basename(file, ".rb").camelize.to_sym, File.join("wrnap", "package", File.basename(file, ".rb")))
    end

    def self.const_missing(name)
      if const_defined?(name)
        const_get(name)
      elsif Base.exec_exists?(name)
        module_eval do
          const_set(name, Class.new(Base))
        end
      end
    end
  end

  def self.debugger
    STDERR.puts yield if Wrnap.debug
  end

  def self.debug
    @debug
  end

  def self.debug=(value)
    @debug = value
  end
end

# -----------------------------------------------------------------------------------------------
# This dirties up the public namespace, but I use it so many times that I want a shorthand to it.
# -----------------------------------------------------------------------------------------------

class Array; include Wrnap::Rna::Wrnapper; end

unless defined? RNA
  def RNA(*args, &block)
    RNA.from_array(args, &block)
  end

  module RNA
    def self.load_all(pattern = "*.fa", &block)
      Wrnap::Rna::Box.load_all(pattern, &block)
    end

    def self.random(size, *args, &block)
      RNA.from_array(args.unshift(Wrnap::Rna.generate_sequence(size).seq), &block)
    end

    def self.method_missing(name, *args, &block)
      if "#{name}" =~ /^from_\w+$/
        Wrnap::Rna.send("init_#{name}", *args, &block)
      else super end
    end
  end
end
