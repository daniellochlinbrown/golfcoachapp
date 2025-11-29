class TrainingPlan < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :handicap_calculation, optional: true

  validates :current_handicap, presence: true,
                               numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 54.0 }
  validates :target_handicap, presence: true,
                              numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 54.0 }
  validates :timeline_months, presence: true,
                              numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 36 }
  validate :target_must_be_lower_than_current

  private

  def target_must_be_lower_than_current
    if target_handicap.present? && current_handicap.present? && target_handicap >= current_handicap
      errors.add(:target_handicap, "must be lower than current handicap")
    end
  end
end
