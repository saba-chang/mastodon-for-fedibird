class CreateStatusReferences < ActiveRecord::Migration[6.1]
  def change
    create_table :status_references do |t|
      t.references :status, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :target_status, null: false, foreign_key: { on_delete: :cascade, to_table: :statuses }, index: false
      t.index [:status_id, :target_status_id], unique: true

      t.timestamps
    end
  end
end
