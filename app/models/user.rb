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
  before_create :generate_confirmation_token

  # Check if user has confirmed their email
  def confirmed?
    confirmed_at.present?
  end

  # Confirm the user's email
  def confirm!
    update(confirmed_at: Time.current, confirmation_token: nil)
  end

  # Send confirmation instructions via email
  def send_confirmation_instructions
    regenerate_confirmation_token unless confirmation_token.present?
    update(confirmation_sent_at: Time.current)
    UserMailer.confirmation_instructions(self).deliver_now
  end

  # Check if confirmation token has expired (24 hours)
  def confirmation_token_expired?
    return true unless confirmation_sent_at
    confirmation_sent_at < 24.hours.ago
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def password_required?
    password_digest.nil? || password.present?
  end

  def generate_confirmation_token
    self.confirmation_token = generate_token
  end

  def regenerate_confirmation_token
    self.confirmation_token = generate_token
    save
  end

  def generate_token
    loop do
      token = SecureRandom.urlsafe_base64(24)
      break token unless User.exists?(confirmation_token: token)
    end
  end
end
