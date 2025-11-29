class CreateTrainingPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :training_plans do |t|
      t.references :user, foreign_key: true
      t.references :handicap_calculation, foreign_key: true
      t.decimal :current_handicap, precision: 4, scale: 1, null: false
      t.decimal :target_handicap, precision: 4, scale: 1, null: false
      t.integer :timeline_months, null: false
      t.text :simple_guide
      t.text :medium_guide
      t.text :complex_guide

      t.timestamps
    end
  end
end
