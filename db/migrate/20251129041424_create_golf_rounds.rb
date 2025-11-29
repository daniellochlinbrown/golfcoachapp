class CreateGolfRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :golf_rounds do |t|
      t.references :user, foreign_key: true
      t.string :course_name, null: false
      t.integer :score, null: false
      t.decimal :course_rating, precision: 4, scale: 1, null: false
      t.integer :slope_rating, null: false
      t.date :played_at

      t.timestamps
    end
  end
end
