class OperationManagementsController < ApplicationController
  before_action :set_operation_management, only: [:show, :update, :destroy]

  # GET /operation_managements
  def index
    @operation_managements = OperationManagement.all

    render json: @operation_managements
  end

  # GET /operation_managements/1
  def show
    render json: @operation_management
  end

  # POST /operation_managements
  def create
    @operation_management = OperationManagement.new(operation_management_params)

    if @operation_management.save
      render json: @operation_management, status: :created, location: @operation_management
    else
      render json: @operation_management.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /operation_managements/1
  def update
    if @operation_management.update(operation_management_params)
      render json: @operation_management
    else
      render json: @operation_management.errors, status: :unprocessable_entity
    end
  end

  # DELETE /operation_managements/1
  def destroy
    @operation_management.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_operation_management
      @operation_management = OperationManagement.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def operation_management_params
      params.require(:operation_management).permit(:operation_name, :operation_id, :std_cycle_time, :load_unload_time, :setup_time, :created_by, :status, :part_per_cycle, :deleted_at, :part_configuration_id, :process_plan_id, :tenant_id)
    end
end
