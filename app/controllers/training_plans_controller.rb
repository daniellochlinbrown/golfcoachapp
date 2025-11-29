class TrainingPlansController < ApplicationController
  before_action :require_login, only: [ :new, :create ]

  # GET /training_plans/new
  def new
    @training_plan = TrainingPlan.new
  end

  # POST /training_plans
  def create
    @training_plan = TrainingPlan.new(training_plan_params)
    @training_plan.user = current_user if logged_in?

    if @training_plan.valid?
      # Generate training plan using Claude API
      begin
        claude_service = ClaudeApiService.new
        guides = claude_service.generate_training_plan(
          @training_plan.current_handicap,
          @training_plan.target_handicap,
          @training_plan.timeline_months
        )

        @training_plan.simple_guide = guides[:simple]
        @training_plan.medium_guide = guides[:medium]
        @training_plan.complex_guide = guides[:complex]

        if @training_plan.save
          flash[:notice] = "Your training plan has been generated!"
          redirect_to training_plan_path(@training_plan)
        else
          flash.now[:alert] = "There was a problem saving your training plan."
          render :new, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error("Training plan generation error: #{e.message}")
        flash.now[:alert] = "There was an error generating your training plan. Please make sure your API key is configured."
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Please correct the errors below."
      render :new, status: :unprocessable_entity
    end
  end

  # GET /training_plans/:id
  def show
    @training_plan = TrainingPlan.find(params[:id])
  end

  # GET /training_plans
  def index
    if logged_in?
      @training_plans = current_user.training_plans.order(created_at: :desc)
    else
      redirect_to login_path, alert: "Please log in to view your training plans."
    end
  end

  private

  def training_plan_params
    params.require(:training_plan).permit(:current_handicap, :target_handicap, :timeline_months)
  end
end
