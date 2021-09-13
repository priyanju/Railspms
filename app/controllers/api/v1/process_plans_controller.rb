 module Api
  module V1
class ProcessPlansController < ApplicationController
  before_action :set_process_plan, only: [:show, :update, :destroy]

  # GET /process_plans
  def index
    @process_plans = Tenant.find(params[:tenant_id]).process_plans.order('plan_number')

    render json: @process_plans
  end

  # GET /process_plans/1
  def show
    render json: @process_plan
  end

  # POST /process_plans
  def create
    @process_plan = ProcessPlan.new(process_plan_params)
    @process_plan.created_by = @current_user.role.role_name
 #   @process_plan.status = true

    if @process_plan.save
      render json: {response: @process_plan, status: true, msg: "Created Successfully"}, status: :ok
    else
      render json: {response: @process_plan.errors, status: false, msg: "Plan_number or part_number has already taken"}, status: :ok
    end

  end

  # PATCH/PUT /process_plans/1
  def update
    if @process_plan.update(process_plan_params)
      render json: {response: @process_plan, status: true, msg: "Updated Successfully"}, status: :ok
    else
      render json: {response: @process_plan, status: false, msg: "Plan_number or part_number has already taken"}, status: :ok
    end
  end

  # DELETE /process_plans/1
  def destroy
    if @process_plan.destroy
      render json: {response: @process_plan, status: true, msg: "Deleted successfully"}, status: :ok
    else
      render json: {response: @process_plan, status: false, msg: "Something went wrong"}, status: :unprocessable_entity
    end

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_process_plan
      @process_plan = ProcessPlan.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def process_plan_params
      params.require(:process_plan).permit(:plan_number, :plan_name, :part_number, :created_by, :status, :plan_description, :part_configuration_id, :deleted_at, :tenant_id)
    end
end
end
end
