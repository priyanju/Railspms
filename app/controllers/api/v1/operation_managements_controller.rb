 module Api
 module V1
class OperationManagementsController < ApplicationController
  before_action :set_operation_management, only: [:show, :update, :destroy]

  # GET /operation_managements
  def index
 #   @operation_managements = Tenant.find(params[:tenant_id]).operation_managements.order('operation_id') 
    @operation_managements = OperationManagement.where(tenant_id: @current_user.tenant_id)
#    @operation_managements = OperationManagement.get_operation_management(params)

    render json: @operation_managements
  end
  
   def get_operation_management
	@operation_management = OperationManagement.find_by_process_plan_id(params[:process_plan_id])	
	if @operation_management.present?
	render json: @operation_management
	else
	render json: false 
	end
   end


  # GET /operation_managements/1
  def show
    render json: @operation_management
  end

  # POST /operation_managements
  def create
     @operation_management = OperationManagement.new(operation_name: params[:operation_name], operation_id: params[:operation_id], std_cycle_time: (Time.parse(params[:std_cycle_time]).seconds_since_midnight).to_i, load_unload_time: (Time.parse(params[:load_unload_time]).seconds_since_midnight).to_i  ,setup_time: (Time.parse(params[:setup_time]).seconds_since_midnight).to_i, created_by: @current_user.role.role_name, status: params[:status], part_per_cycle: params[:part_per_cycle], part_configuration_id: params[:part_configuration_id], tenant_id: params[:tenant_id], process_plan_id: params[:process_plan_id])
  
    
    if @operation_management.save
      render json: {response: @operation_management, status: true, msg: "Created Successfully"}, status: :ok
    else
      render json: {response: @operation_management.errors, status: false, msg: "Operation_id has already taken"}, status: :ok
    end

  end

  # PATCH/PUT /operation_managements/1
  def update
   if @operation_management.update(operation_name: params[:operation_name], operation_id: params[:operation_id], std_cycle_time: (Time.parse(params[:std_cycle_time]).seconds_since_midnight).to_i, load_unload_time: (Time.parse(params[:load_unload_time]).seconds_since_midnight).to_i  ,setup_time: (Time.parse(params[:setup_time]).seconds_since_midnight).to_i, created_by: @current_user.role.role_name, status: params[:status], part_per_cycle: params[:part_per_cycle], part_configuration_id: params[:part_configuration_id], tenant_id: params[:tenant_id], process_plan_id: params[:process_plan_id])
      render json: {response: @operation_management, status: true, msg: "Updated Successfully"}, status: :ok
    else
      render json: {response: @operation_management, status: false, msg: "Operation_id has already taken"}, status: :ok
    end
  end

  # DELETE /operation_managements/1
  def destroy
    if @operation_management.delete
      render json: {response: @operation_management, status: true, msg: "Deleted successfully"}, status: :ok
    else
      render json: {response: @operation_management, status: false, msg: "Something went wrong"}, status: :unprocessable_entity
    end
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
end
end
