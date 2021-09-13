class ProcessPlansController < ApplicationController
  before_action :set_process_plan, only: [:show, :update, :destroy]

  # GET /process_plans
  def index
    @process_plans = ProcessPlan.all

    render json: @process_plans
  end

  # GET /process_plans/1
  def show
    render json: @process_plan
  end

  # POST /process_plans
  def create
    @process_plan = ProcessPlan.new(process_plan_params)

    if @process_plan.save
      render json: @process_plan, status: :created, location: @process_plan
    else
      render json: @process_plan.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /process_plans/1
  def update
    if @process_plan.update(process_plan_params)
      render json: @process_plan
    else
      render json: @process_plan.errors, status: :unprocessable_entity
    end
  end

  # DELETE /process_plans/1
  def destroy
    @process_plan.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_process_plan
      @process_plan = ProcessPlan.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def process_plan_params
      params.require(:process_plan).permit(:plan_number, :plan_name, :part_no, :created_by, :status, :deleted_at, :tenant_id)
    end
end
