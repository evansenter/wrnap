module Wrnap
  module DB
    class Config
      include Singleton, Virtus.model

      attribute :env, String, default: "wrnap"

      attribute :rfam_file, String, default: ->(_, _) {
        File.expand_path("../../../../db/rfam_12.seed.utf8", __FILE__)
      }

      attribute :config, Hash[String => String], default: ->(_, _) {
        YAML.load_file(File.expand_path("../../../../db/config.yml", __FILE__))
      }

      def scoped_config
        config[env]
      end

      def bootstrap!
        ensure_action("Are you sure you'd like to completely rebuild the database? This takes around 20 minutes.") do
          Rake::Task["db:reset"].invoke
        end
      end

      def seed!
        ensure_action("Are you sure you'd like to re-seed the database? This is faster than bootstrap!, and won't delete data.") do
          Rake::Task["db:seed"].invoke
        end
      end

      def clear!
        ensure_action("Are you sure you'd like drop the database? This can't be un-done.") do
          Rake::Task["db:drop"].invoke
        end
      end

      private

      def ensure_action(string, &block)
        puts "#{string} (y/n)"
        response = gets.chomp.downcase
        if response == ?y
          load_rakefile
          yield block
          true
        else
          puts "Bailing, no changes were made."
          false
        end
      end

      def load_rakefile
        Rake.load_rakefile(File.expand_path("../../../../Rakefile", __FILE__))
      end
    end
  end
end
