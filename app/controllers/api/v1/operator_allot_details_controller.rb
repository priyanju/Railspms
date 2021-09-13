 module Api
 module V1
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
	@get_data = @operator_allot_detail.operator_allocation.shifttransaction
	date = @operator_allot_detail.operator_allocation.date
	all_shift = []
      shifts = Shifttransaction.all
      shifts.map do |ll|
      case
      when @get_data.day == '1' && @get_data.end_day == '1'
        all_shift << [@get_data.shift_start_time.to_time..@get_data.shift_end_time.to_time]
      when @get_data.day == '1' && @get_data.end_day == '2'
        all_shift <<  [@get_data.shift_start_time.to_time..@get_data.shift_end_time.to_time+1.day]
      else start_time = @get_data.shift_start_time.to_time
        all_shift << [@get_data.shift_start_time.to_time+1.day..@get_data.shift_end_time.to_time+1.day]
      end
     end
     if @get_data.day == "1" && @get_data.end_day=="1"
       start_time = @get_data.shift_start_time.to_time
       end_time = @get_data.shift_end_time.to_time
     elsif @get_data.day == "1" && @get_data.end_day=="2"
       start_time = @get_data.shift_start_time.to_time
       end_time = @get_data.shift_end_time.to_time+1.day
     else
       shift_time = @get_data.shift_start_time.to_time+1.day
       end_time = @get_data.shift_end_time.to_time+1.day
     end
    shift_status = []
   all_shift.each do |aa|
     if aa.first.cover?(start_time) || aa.first.cover?(end_time)
       shift_status << true
     else
       shift_status << false
     end
   end

if shift_status.include?(true)
	data1 = @operator_allot_detail.operator_allocation.date.to_date
	time1 = end_time.strftime("%I:%M%p")
	time2 = start_time.strftime("%I:%M%p")
        
        @operator_allot_detail.start_time = DateTime.parse("#{data1} #{time1}")
	@operator_allot_detail.end_time = DateTime.parse("#{data1} #{time2}")

	if @operator_allot_detail.save
		 render json: @operator_allot_detail
	else
      	       	 render json: @operator_allot_detail.errors, status: :unprocessable_entity
    	end
else
	render json: false
end
      
  end
  # PATCH/PUT /operator_allot_details/1
  def update
	time = Time.now
	@operator_allot_detail = OperatorAllotDetail.where(operation_management_id: params[:operation_management_id], operator_allocation_id: params[:operator_allocation_id], operator_id: params[:operator_id]) if params[:operation_management_id].present? && params[:operator_allocation_id].present? && params[:operator_id].present?
#	@operator_allot_detail = OperatorAllocation.joins(:operator_allot_details).where("operation_management_id: params[:operation_management_id]", "operator_allocation_id: params[:operator_allocation_id]", "operator_id: params[:operator_id]") if params[:operation_management_id].present? && params[:operator_allocation_id].present? && params[:operator_id].present?
	data1 = @operator_allot_detail.operator_allocation.date.to_date
        time1 = Time.now.strftime("%I:%M%p")
        time2 = Time.now.strftime("%I:%M%p")
	start_time = DateTime.parse("#{data1} #{time1}")
	end_time = DateTime.parse("#{data1} #{time2}")
	if @operator_allot_detail.present?
		@a =  @operator_allot_detail.end_time.update(Time.now)
		@b =  OperatorAllotDetail.new(operation_management_id: params[:operation_management_id], operator_allocation_id: params[:operator_allocation_id], operator_id: params[:operator_id], end_time: end_time, start_time: start_time)
		if @a.update && @b.save
			render json: {updated: @a, created: @b, status: true, msg: "Operator Reassigned successfully"}, status: :created
		else
			render json: false
		end
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
end
end
