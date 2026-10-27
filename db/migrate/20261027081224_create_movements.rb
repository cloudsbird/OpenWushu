class CreateMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :movements do |t|
      t.references :routine, null: false, foreign_key: true
      t.integer :number, null: false
      t.integer :section, null: false, default: 1
      t.string :name_zh, null: false
      t.string :name_pinyin, null: false
      t.string :name_en, null: false
      t.string :name_id, null: false
      t.float :start_sec, null: false, default: 0
      t.float :end_sec, null: false, default: 0
      # Where the movement ends on the 14 m × 8 m carpet, in metres from the top-left corner
      t.float :end_x
      t.float :end_y
      t.string :facing_en
      t.string :facing_id
      # Translated lists: { "en" => [...], "id" => [...] }
      t.json :steps, null: false, default: {}
      t.json :key_points, null: false, default: {}
      t.json :mistakes, null: false, default: {}
      # 图解 poses for the 3D figure, one per step: [{ "yaw" => deg, "j" => [[x, y, z], ...] }]
      t.json :figures, null: false, default: []
      t.string :reference

      t.timestamps
    end
    add_index :movements, [ :routine_id, :number ], unique: true
  end
end
