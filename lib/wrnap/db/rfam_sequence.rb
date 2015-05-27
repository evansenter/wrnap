module Wrnap
  module DB
    class RfamSequence < ActiveRecord::Base
      establish_connection Wrnap.db.scoped_config

      belongs_to :rfam_family

      validates :accession, :from, :to, :sequence, :gapped_sequence, presence: true
      validates :from, :to, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
      validates :accession, uniqueness: { scope: [:sequence, :from, :to] }

      scope :plus_strand,  ->{ where(arel_table[:to].gt(arel_table[:from])) }
      scope :minus_strand, ->{ where(arel_table[:to].lt(arel_table[:from])) }

      def wrnap
        Wrnap::Rna::Context.init_from_string(*instance_eval { [sequence, accession, from, to] })
      end
    end
  end
end
