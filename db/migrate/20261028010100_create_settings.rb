# One row of site-wide settings, edited in the admin panel
class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.boolean :signups_open, null: false, default: true
      t.boolean :verification_required, null: false, default: true
      t.text :notice_en
      t.text :notice_id

      t.string :site_name, null: false, default: "OpenWushu"
      t.string :contact_email
      t.text :footer_en
      t.text :footer_id
      t.string :source_url, null: false, default: "https://github.com/cloudsbird/OpenWushu"

      t.string :mail_from
      t.string :smtp_address
      t.integer :smtp_port
      t.string :smtp_username
      t.text :smtp_password

      t.timestamps
    end
  end
end
