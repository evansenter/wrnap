class RenameFamiliesTableToRfamFamilies < ActiveRecord::Migration
  def change
  	rename_table :families, :rfam_families
  	rename_column :rfam_sequences, :family_id, :rfam_family_id
  end
end
