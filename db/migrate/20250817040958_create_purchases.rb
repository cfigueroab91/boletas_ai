class CreatePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases do |t|
      t.string :supplier
      t.string :rut
      t.date :date
      t.decimal :total, precision: 12, scale: 2
      t.jsonb   :items, default: []
      t.text :raw_text

      t.timestamps
    end
  end
end
