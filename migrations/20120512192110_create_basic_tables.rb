class CreateBasicTables < ActiveRecord::Migration
  def change
    create_table(:bits) do |t|
      t.string :name
      t.integer :group_id
    end

    create_table(:groups) do |t|
      t.string :name
    end
    add_index :groups, :name, unique: true

    create_table(:users) do |t|
      t.string :name
    end

    create_table(:permissions) do |t|
      t.integer :user_id
      t.integer :bit_id
    end
  end
end
