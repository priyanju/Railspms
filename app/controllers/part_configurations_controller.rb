class PartConfigurationsController < ApplicationController
  before_action :set_part_configuration, only: [:show, :update, :destroy]

  # GET /part_configurations
  def index
    @part_configurations = PartConfiguration.all

    render json: @part_configurations
  end

  # GET /part_configurations/1
  def show
    render json: @part_configuration
  end

  # POST /part_configurations
  def create
    @part_configuration = PartConfiguration.new(part_configuration_params)

    if @part_configuration.save
      render json: @part_configuration, status: :created, location: @part_configuration
    else
      render json: @part_configuration.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /part_configurations/1
  def update
    if @part_configuration.update(part_configuration_params)
      render json: @part_configuration
    else
      render json: @part_configuration.errors, status: :unprocessable_entity
    end
  end

  # DELETE /part_configurations/1
  def destroy
    @part_configuration.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_part_configuration
      @part_configuration = PartConfiguration.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def part_configuration_params
      params.require(:part_configuration).permit(:part_number, :part_name, :customer_name, :is_active, :part_description, :tenant_id, :role_id)
    end
end
