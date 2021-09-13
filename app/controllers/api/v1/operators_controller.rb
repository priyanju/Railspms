module Api
  module V1
class OperatorsController < ApplicationController
  before_action :set_operator, only: [:show, :update, :destroy]

  # GET /operators
  def index

    @operators = Tenant.find(params[:tenant_id]).operators.order('operator_name')

    render json: @operators
  end

  # GET /operators/1
  def show
    render json: @operator
  end

  # POST /operators
  def create
    @operator = Operator.new(operator_params)
    @operator.created_by= @current_user.role.role_name

    if @operator.save

      render json: {response: @operator, status:true, msg: "Operator Created Successfully"},status: :ok

    else
      render json: {response: @operator.errors,  status:false, msg:"Operator_id has already taken"}, status: :ok
    end
  end

  # PATCH/PUT /operators/1
  def update
    if @operator.update(operator_params)
      render json: {response: @operator, status: true, msg: "Updated successfully"}, status: :ok
    else
      render json: {response: @operator, status: false, msg: "Operator_id has already taken"}, status: :ok
    end
  end

  # DELETE /operators/1
  def destroy
    @operator.destroy
      if @operator.destroy
      render json: {response: @operator, status: true, msg: "Deleted successfully"}, status: :ok
    else
      render json: {response: @operator, status: false, msg: "Something went wrong"}, status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_operator
      @operator = Operator.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def operator_params
      params.require(:operator).permit(:operator_name, :operator_spec_id, :description, :tenant_id)
    end
end
end
end
