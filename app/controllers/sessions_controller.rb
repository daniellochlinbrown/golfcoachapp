class SessionsController < ApplicationController
  # GET /login
  def new
  end

  # POST /login
  def create
    user = User.find_by(email: params[:email].downcase)

    if user&.authenticate(params[:password])
      if user.confirmed?
        log_in(user)
        flash[:notice] = "Welcome back, #{user.email}!"
        redirect_to root_path
      else
        flash.now[:alert] = "Please confirm your email address before logging in. Check your inbox or request a new confirmation email."
        @resend_confirmation_link = new_confirmation_path
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /logout
  def destroy
    log_out
    flash[:notice] = "You have been logged out."
    redirect_to root_path
  end
end
