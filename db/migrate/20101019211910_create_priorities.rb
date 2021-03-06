class CreatePriorities < ActiveRecord::Migration
  def self.up
    create_table :priorities do |t|
      t.string :dbcode
      t.string :label
      t.integer :priority

      t.timestamps
    end
  end

  def self.down
    drop_table :priorities
  end
end
