class RenameRnasTableToRfamSequences < ActiveRecord::Migration
  def change
  	rename_table :rnas, :rfam_sequences
  end
end
