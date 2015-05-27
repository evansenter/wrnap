module Wrnap
  module DB
    class RfamFamily < ActiveRecord::Base
      establish_connection Wrnap.db.scoped_config

      has_many :seqs, class_name: "RfamSequence" do
        def wrnap
          Wrnap::Rna::Box.new(rnas: to_a.map(&:wrnap), name: proxy_association.owner.name)
        end
      end

      validates :name, :description, :consensus_structure, presence: true
      validates :name, uniqueness: true

      def self.rf(id)
        int_id = id.to_i
        find_by_name("RF%s%d" % [?0 * (5 - Math.log10(int_id).ceil), int_id])
      end

      def self.named(string)
        where(arel_table[:description].matches("%#{string}%"))
      end

      def wrnap
        seqs.wrnap
      end
    end
  end
end
