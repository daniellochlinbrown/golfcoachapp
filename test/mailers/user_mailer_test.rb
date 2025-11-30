require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "confirmation_instructions" do
    user = users(:one)
    user.update(confirmation_token: "test_token_123", confirmed_at: nil)

    mail = UserMailer.confirmation_instructions(user)

    assert_equal "Confirm your Golf Coach App account", mail.subject
    assert_equal [ user.email ], mail.to
    assert_equal [ "noreply@golfcoachapp.com" ], mail.from
    assert_match "Welcome to Golf Coach App", mail.body.encoded
    assert_match "Confirm My Email", mail.body.encoded
    assert_match user.confirmation_token, mail.body.encoded
  end
end
