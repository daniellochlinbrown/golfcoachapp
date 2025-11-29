class GolfRoundsController < ApplicationController
  # GET /golf_rounds/new
  def new
    # Store rounds in session for guest users
    session[:rounds] ||= []
    @rounds_data = session[:rounds]
  end

  # POST /golf_rounds
  def create
    rounds_params = params[:rounds] || {}

    # Convert hash to array of values
    rounds_array = rounds_params.values

    # Validate we have 3 rounds
    if rounds_array.length != 3
      flash.now[:alert] = "Please enter exactly 3 rounds of golf."
      render :new, status: :unprocessable_entity
      return
    end

    # Create golf rounds
    @golf_rounds = []
    errors = []

    rounds_array.each_with_index do |round_data, index|
      round = GolfRound.new(
        user: current_user,
        course_name: round_data[:course_name],
        score: round_data[:score],
        course_rating: round_data[:course_rating],
        slope_rating: round_data[:slope_rating],
        played_at: round_data[:played_at]
      )

      if round.valid?
        @golf_rounds << round
      else
        errors << "Round #{index + 1}: #{round.errors.full_messages.join(', ')}"
      end
    end

    if errors.any?
      flash.now[:alert] = errors.join("; ")
      render :new, status: :unprocessable_entity
      return
    end

    # Save all rounds
    @golf_rounds.each(&:save)

    # Store round IDs in session for handicap calculation
    session[:golf_round_ids] = @golf_rounds.map(&:id)

    redirect_to new_handicap_calculation_path
  end

  # GET /golf_rounds
  def index
    if logged_in?
      @golf_rounds = current_user.golf_rounds.order(played_at: :desc)
    else
      redirect_to login_path, alert: "Please log in to view your rounds."
    end
  end
end
