class CreateRoutines < ActiveRecord::Migration[8.0]
  def change
    create_table :routines do |t|
      t.string :slug, null: false
      t.string :style, null: false
      t.string :name_zh, null: false
      t.string :name_pinyin, null: false
      t.string :name_en, null: false
      t.string :name_id, null: false
      t.string :card_zh
      t.string :status, null: false, default: "awaiting"
      t.integer :position, null: false, default: 0
      t.integer :reference_page
      t.string :reference_figure
      t.float :start_x
      t.float :start_y

      t.timestamps
    end
    add_index :routines, :slug, unique: true
  end
end
