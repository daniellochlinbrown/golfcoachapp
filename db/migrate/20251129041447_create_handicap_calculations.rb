class CreateHandicapCalculations < ActiveRecord::Migration[8.1]
  def change
    create_table :handicap_calculations do |t|
      t.references :user, foreign_key: true
      t.decimal :calculated_handicap, precision: 4, scale: 1, null: false
      t.string :calculation_method, default: "predicted"
      t.text :ai_context

      t.timestamps
    end
  end
end
