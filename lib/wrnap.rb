require "active_record"
require "active_support"
require "autoloaded"
require "benchmark"
require "bigdecimal"
require "bio"
require "bio-stockholm"
require "entrez"
require "meta_missing"
require "numbers_in_words"
require "numbers_in_words/duck_punch"
require "parallel"
require "ptools"
require "rake"
require "rroc"
require "scanf"
require "set"
require "shuffle"
require "singleton"
require "tempfile"
require "tree"
require "virtus"
require "yaml"

module Wrnap
  Autoloaded.module {}

  module DB
    Autoloaded.module { |loader| loader.from(File.expand_path("../wrnap/db", __FILE__)) }
  end

  module Etl
    Autoloaded.module { |loader| loader.from(File.expand_path("../wrnap/etl", __FILE__)) }
  end

  module Global
    Autoloaded.module { |loader| loader.from(File.expand_path("../wrnap/global", __FILE__)) }
  end

  RT     = 1e-3 * 1.9872041 * (273.15 + 37) # kcal / K / mol @ 37C
  @debug = true

  def self.patch_array!
    Array.send(:include, Wrnap::Rna::Wrnapper)
  end

  def self.db
    DB::Config.instance
  end

  def self.rfam(id)
    Wrnap::DB::RfamFamily.rf(id).wrnap
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

unless defined?(RNA)
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
