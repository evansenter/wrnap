require "benchmark"
require "set"
require "shuffle"
require "rinruby"
require "tempfile"
require "bigdecimal"
require "rroc"
require "active_support/inflector"
require "active_support/core_ext/class"

require "wrnap/version"
require "wrnap/global/rna_extensions"
require "wrnap/global/rna"
require "wrnap/global/parser"
require "wrnap/global/run_extensions"
require "wrnap/global/chain_extensions"
require "wrnap/graphing/r"
require "wrnap/package/base"

begin; R.quit; rescue IOError; end

module Wrnap
  RT     = 1e-3 * 1.9872041 * (273.15 + 37) # kcal / K / mol @ 37C
  @debug = true

  module Package
    Dir[File.join(File.dirname(__FILE__), "wrnap", "package", "*.rb")].reject { |file| file =~ /\/base.rb/ }.each do |file|
      autoload(File.basename(file, ".rb").camelize.to_sym, "wrnap/package/#{File.basename(file, '.rb')}")
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

  def self.deserialize(string)
    YAML.load(File.exist?(string) ? File.read(string) : string)
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

# This dirties up the public namespace, but I use it so many times that I want a shorthand to it
unless defined? RNA
  def RNA(*args)
    RNA.from_array(args)
  end
end

module RNA
  def self.load_all(pattern = "*.fa")
    Dir[File.directory?(pattern) ? pattern + "/*.fa" : pattern].map { |file| RNA.from_fasta(file) }
  end

  def self.random(size, *args)
    RNA.from_array(args.unshift(Wrnap::Global::Rna.generate_sequence(size).seq))
  end

  def self.method_missing(name, *args, &block)
    if "#{name}" =~ /^from_\w+$/
      Wrnap::Global::Rna.send("init_#{name}", *args)
    else super end
  end
end
