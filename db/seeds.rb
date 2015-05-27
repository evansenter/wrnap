require "wrnap"
require "activerecord-import/base"

puts "Parsing %s to load in DB." % Wrnap.db.rfam_file
entries = Bio::Stockholm::Reader.parse_from_file(Wrnap.db.rfam_file) and nil
puts "Loading up %d RFam families." % entries.size

Parallel.each(entries, in_processes: 0, progress: "Populating SQLite DB") do |stockholm|
  family = Wrnap::DB::Family.find_or_create_by(
    name:                stockholm.gf_features["AC"],
    description:         stockholm.gf_features["DE"],
    consensus_structure: stockholm.gc_features["SS_cons"]
  )

  existing_sequences = family.rnas.map { |sequence| sequence.instance_eval { "%s/%d-%d" % [accession, from, to] } }.to_set
  sequences          = stockholm.records.reject do |key, _|
    # Parse error in the Bio::Stockholm library necessitates the # check
    key == ?# || existing_sequences.include?(key)
  end.map do |identifier, record|
    accession, from, to = identifier.split(/[\/-]/)

    Wrnap::DB::Rna.find_or_initialize_by(
      family:    family,
      accession: accession,
      from:      from,
      to:        to
    ) do |sequence|
      sequence.gapped_sequence = record.sequence.upcase
      sequence.sequence        = sequence.gapped_sequence.gsub(/[^AUGC]/, "")
    end
  end

  Wrnap::DB::Rna.import(sequences.select(&:new_record?))
end and nil
