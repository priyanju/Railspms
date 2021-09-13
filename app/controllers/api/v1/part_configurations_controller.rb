 module Api
  module V1
class PartConfigurationsController < ApplicationController
  before_action :set_part_configuration, only: [:show, :update, :destroy]

  # GET /part_configurations
  def index
    @part_configurations = Tenant.find(params[:tenant_id]).part_configurations.order('part_number')

    render json: @part_configurations
  end

  # GET /part_configurations/1
  def show
    render json: @part_configuration
  end

  # POST /part_configurations
  def create
    @part_configuration = PartConfiguration.new(part_configuration_params)
    @part_configuration.created_by = @current_user.role.role_name
 #   @part_configuration.is_active = true

    if @part_configuration.save
      render json: {response: @part_configuration, status: true, msg: "Created Successfully"}, status: :ok
    else
      render json: {response: @part_configuration.errors, status: false, msg: "Part_number has already taken"}, status: :ok
    end
  end

  # PATCH/PUT /part_configurations/1
  def update
    if @part_configuration.update(part_configuration_params)
      render json: {response: @part_configuration, status: true, msg: "Updated Successfully"}, status: :ok
    else
      render json: {response: @part_configuration, status: false, msg: "Part_number has already taken"}, status: :ok
    end
  end

  # DELETE /part_configurations/1
  def destroy
    if @part_configuration.destroy
      render json: {response: @part_configuration, status: true, msg: "Deleted successfully"}, status: :ok
    else
      render json: {response: @part_configuration, status: false, msg: "Something went wrong"}, status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_part_configuration
      @part_configuration = PartConfiguration.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def part_configuration_params
      params.require(:part_configuration).permit(:part_number, :part_name, :customer_name, :status, :part_description, :tenant_id, :role_id)
    end
end
end
end
