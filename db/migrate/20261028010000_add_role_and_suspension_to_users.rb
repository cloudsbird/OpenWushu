class AddRoleAndSuspensionToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: "member"
    add_column :users, :suspended_at, :datetime
    add_index :users, :role
  end
end
