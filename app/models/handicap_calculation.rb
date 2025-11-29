class HandicapCalculation < ApplicationRecord
  belongs_to :user, optional: true
  has_many :handicap_calculation_rounds, dependent: :destroy
  has_many :golf_rounds, through: :handicap_calculation_rounds
  has_many :training_plans, dependent: :nullify

  validates :calculated_handicap, presence: true,
                                  numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 54.0 }
  validates :calculation_method, presence: true, inclusion: { in: %w[official predicted] }
end
