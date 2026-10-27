class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :display_name, null: false
      t.string :locale, null: false, default: "en"
      t.string :club
      t.datetime :verified_at
      t.datetime :guidelines_accepted_at, null: false

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
