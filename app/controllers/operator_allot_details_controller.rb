class OperatorAllotDetailsController < ApplicationController
  before_action :set_operator_allot_detail, only: [:show, :update, :destroy]

  # GET /operator_allot_details
  def index
    @operator_allot_details = OperatorAllotDetail.all

    render json: @operator_allot_details
  end

  # GET /operator_allot_details/1
  def show
    render json: @operator_allot_detail
  end

  # POST /operator_allot_details
  def create
    @operator_allot_detail = OperatorAllotDetail.new(operator_allot_detail_params)

    if @operator_allot_detail.save
      render json: @operator_allot_detail, status: :created, location: @operator_allot_detail
    else
      render json: @operator_allot_detail.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /operator_allot_details/1
  def update
    if @operator_allot_detail.update(operator_allot_detail_params)
      render json: @operator_allot_detail
    else
      render json: @operator_allot_detail.errors, status: :unprocessable_entity
    end
  end

  # DELETE /operator_allot_details/1
  def destroy
    @operator_allot_detail.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_operator_allot_detail
      @operator_allot_detail = OperatorAllotDetail.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def operator_allot_detail_params
      params.require(:operator_allot_detail).permit(:operation_management_id, :operator_allocation_id, :tenant_id, :operator_id, :end_time, :start_time)
    end
end
