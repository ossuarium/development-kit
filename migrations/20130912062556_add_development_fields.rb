class AddDevelopmentFields < ActiveRecord::Migration
  def change
    add_column :bits, :path, :string
    add_column :bits, :root_domain, :string
    add_column :bits, :commit, :string
    add_column :groups, :repository, :string
  end

  create_table(:databases) do |t|
    t.integer :group_id
    t.string :name
    t.string :engine
    t.string :host
    t.string :username
    t.string :password
  end
  add_index :databases, :group_id, unique: false
end
