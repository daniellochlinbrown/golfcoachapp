class UsersController < ApplicationController
  # GET /signup
  def new
    @user = User.new
  end

  # POST /signup
  def create
    @user = User.new(user_params)

    if @user.save
      # Email confirmation disabled for prototype
      # To re-enable: uncomment the lines below and comment out log_in
      # @user.send_confirmation_instructions
      # flash[:notice] = "Welcome! Please check your email to confirm your account before logging in."

      log_in(@user)
      flash[:notice] = "Welcome to Golf Coach! Your account has been created."
      redirect_to root_path
    else
      flash.now[:alert] = "There was a problem creating your account."
      render :new, status: :unprocessable_entity
    end
  end

  # GET /users/:id
  def show
    @user = User.find(params[:id])
    @training_plans = @user.training_plans.order(created_at: :desc)
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
