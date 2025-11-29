class GolfRound < ApplicationRecord
  belongs_to :user, optional: true
  has_many :handicap_calculation_rounds, dependent: :destroy
  has_many :handicap_calculations, through: :handicap_calculation_rounds

  validates :course_name, presence: true, length: { minimum: 3 }
  validates :score, presence: true,
                    numericality: { only_integer: true, greater_than: 50, less_than: 200 }
  validates :course_rating, presence: true,
                            numericality: { greater_than: 60.0, less_than: 80.0 }
  validates :slope_rating, presence: true,
                           numericality: { only_integer: true, greater_than: 55, less_than: 155 }

  # Calculate score differential for this round
  def score_differential
    (113.0 / slope_rating) * (score - course_rating)
  end
end
