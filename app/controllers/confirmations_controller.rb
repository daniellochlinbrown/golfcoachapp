class ConfirmationsController < ApplicationController
  # GET /confirmations/:token
  def show
    @user = User.find_by(confirmation_token: params[:token])

    if @user.nil?
      flash[:alert] = "Invalid confirmation token. Please request a new confirmation email."
      redirect_to root_path
    elsif @user.confirmed?
      flash[:notice] = "Your email is already confirmed. Please log in."
      redirect_to login_path
    elsif @user.confirmation_token_expired?
      flash[:alert] = "Your confirmation token has expired. Please request a new confirmation email."
      redirect_to new_confirmation_path
    else
      @user.confirm!
      flash[:notice] = "Thank you! Your email has been confirmed. You can now log in."
      redirect_to login_path
    end
  end

  # GET /confirmations/new
  def new
    # Form to request a new confirmation email
  end

  # POST /confirmations
  def create
    @user = User.find_by(email: params[:email].downcase)

    if @user.nil?
      flash.now[:alert] = "No account found with that email address."
      render :new, status: :unprocessable_entity
    elsif @user.confirmed?
      flash[:notice] = "Your email is already confirmed. Please log in."
      redirect_to login_path
    else
      @user.send_confirmation_instructions
      flash[:notice] = "Confirmation email sent! Please check your inbox."
      redirect_to root_path
    end
  end
end
