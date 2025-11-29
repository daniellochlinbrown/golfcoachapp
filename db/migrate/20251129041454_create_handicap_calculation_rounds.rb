class CreateHandicapCalculationRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :handicap_calculation_rounds do |t|
      t.references :handicap_calculation, null: false, foreign_key: true
      t.references :golf_round, null: false, foreign_key: true

      t.timestamps
    end
  end
end
