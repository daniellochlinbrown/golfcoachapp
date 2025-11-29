class HandicapCalculationsController < ApplicationController
  # GET /handicap_calculations/new
  def new
    # Get golf rounds from session
    round_ids = session[:golf_round_ids]

    unless round_ids&.length == 3
      flash[:alert] = "Please upload 3 rounds first."
      redirect_to new_golf_round_path
      return
    end

    @golf_rounds = GolfRound.where(id: round_ids).order(:created_at)

    # Calculate handicap
    calculator = HandicapCalculatorService.new(@golf_rounds)
    @calculated_handicap = calculator.calculate

    # Create handicap calculation
    @handicap_calculation = HandicapCalculation.new(
      user: current_user,
      calculated_handicap: @calculated_handicap,
      calculation_method: "predicted"
    )

    # Associate rounds with calculation
    @golf_rounds.each do |round|
      @handicap_calculation.golf_rounds << round
    end

    # Optionally get AI context
    begin
      claude_service = ClaudeApiService.new
      @ai_context = claude_service.generate_handicap_context(@golf_rounds, @calculated_handicap)
      @handicap_calculation.ai_context = @ai_context
    rescue => e
      Rails.logger.error("Handicap context generation error: #{e.message}")
      @ai_context = "Your predicted handicap is #{@calculated_handicap}. This represents your current skill level based on the three rounds you submitted."
      @handicap_calculation.ai_context = @ai_context
    end

    # Save the calculation
    @handicap_calculation.save

    # Store in session for training plan
    session[:handicap_calculation_id] = @handicap_calculation.id
  end

  # POST /handicap_calculations (not used in current flow, but available)
  def create
    redirect_to new_handicap_calculation_path
  end

  # GET /handicap_calculations/:id
  def show
    @handicap_calculation = HandicapCalculation.find(params[:id])
    @golf_rounds = @handicap_calculation.golf_rounds
  end
end
