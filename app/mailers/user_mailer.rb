class UserMailer < ApplicationMailer
  default from: "daniel.brown27@hotmail.com"

  def confirmation_instructions(user)
    @user = user
    @confirmation_url = confirmation_url(token: @user.confirmation_token)

    mail(
      to: @user.email,
      subject: "Confirm your Golf Coach App account"
    )
  end
end
