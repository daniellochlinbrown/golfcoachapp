class User < ApplicationRecord
  has_secure_password

  has_many :golf_rounds, dependent: :destroy
  has_many :handicap_calculations, dependent: :destroy
  has_many :training_plans, dependent: :destroy

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: :password_required?

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def password_required?
    password_digest.nil? || password.present?
  end
end
