# Every change to a movement's text: who wrote it, who reviewed it, and full snapshots before and after.
# Published revisions are the movement's history and its CC BY-SA attribution record.
class CreateRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :revisions do |t|
      t.references :movement, null: false, foreign_key: true
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :reviewer, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :restored_from, foreign_key: { to_table: :revisions, on_delete: :nullify }
      t.string :status, null: false, default: "pending"
      t.string :summary, null: false
      t.string :source
      t.text :note
      t.jsonb :before, null: false, default: {}
      t.jsonb :after, null: false, default: {}
      t.datetime :reviewed_at

      t.timestamps
    end
    add_index :revisions, %i[status created_at]
    add_index :revisions, %i[movement_id status]
  end
end
