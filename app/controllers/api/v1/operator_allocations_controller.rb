module Api
  module V1
class OperatorAllocationsController < ApplicationController
  before_action :set_operator_allocation, only: [:show, :update, :destroy]

  # GET /operator_allocations
  def index
    #@operator_allocations = OperatorAllocation.all
    #byebug
    @operator_allocations = OperatorAllocation.all.order("date DESC")#.all#where(tenant_id:params[:tenant_id],from_date:Date.today-5..Date.today+20)
    #@operator_allocations = OperatorMappingAllocation.includes(:operator_allocation).where(operator_allocations: {tenant_id:params[:tenant_id]}).where(date:Date.today..Date.today+20)
                    render json: @operator_allocations,status: :ok
  end


   def index1
    page = params[:page].present? ? params[:page] : 1
    page_count = params[:per_page].present? ? params[:per_page] :20

 #   @alarm_histories = AlarmTest.includes(:machine).order(:time).reverse#.where(machines: {tenant_id:params[:tenant_id]}).order(:time).reverse
 #  @alarm_histories = AlarmHistory.includes(:machine).where(machines: {tenant_id:params[:tenant_id]}).order(:time).reverse
    all_alarms = AlarmTest.order("time DESC")#all.#order_by(:time.desc)
    alarms =  all_alarms.paginate(:page => page, :per_page => page_count)

#    alarms = AlarmTest.all
    alarm = alarms.map{|i| [id: i["id"],alarm_type: i["alarm_type"],alarm_no: i["alarm_no"],axis_no: i["axis_no"],time: i["time"],message: i["message"],alarm_status: i["alarm_status"],machine_id: i["machine_id"],created_at: i["created_at"],updated_at: i["updated_at"]]}
    alarm.flatten!
    render json: alarms
	
   end

  # GET /operator_allocations/1
  def show
    render json: @operator_allocation
  end

  # POST /operator_allocations
  def create
	@operator_allocation = OperatorAllocation.new(operator_allocation_params)
	@operator_allocation.created_by = @current_user.role.role_name
		if @operator_allocation.save
		      render json: {response: @operator_allocation, status: true, msg: "Created Successfully"}, status: :ok
	        else
 		      render json: {response: @operator_allocation.errors, status: false, msg: "The machine has already taken"}, status: :ok
	        end	
  end

  def update
    date = @operator_allocation.date.strftime("%Y-%m-%d")
    shift = @operator_allocation.shifttransaction
     case
       when shift.day == 1 && shift.end_day == 1
         start_time = (date+" "+shift.shift_start_time).to_time
         end_time = (date+" "+shift.shift_end_time).to_time
       when shift.day == 1 && shift.end_day == 2
         start_time = (date+" "+shift.shift_start_time).to_time
         end_time = (date+" "+shift.shift_end_time).to_time+1.day
       when shift.day == 2 && shift.end_day == 2
         start_time = (date+" "+shift.shift_start_time).to_time+1.day
         end_time = (date+" "+shift.shift_end_time).to_time+1.day
       end
#byebug
#	time = Time.now.strftime("%I:%M:%S +000")
     if (start_time..end_time).include?(Time.now) 
      		if @operator_allocation.update(operator_allocation_params)       
			render json: {response: @operator_allocation, status: true, msg: "successfully created"}, status: :created
      		else
			render json: {response: @operator_allocation.errors, status: false, msg: "The machine has already taken"}, status: :ok
    	 	end
     else
	render json: {status: false, msg: "Update only in current shift"}, status: :ok
	
     end
  end 
  # PATCH/PUT /operator_allocations/1
  def update1
     if  @operator_mapping_allocation = OperatorMappingAllocation.update(:operator_id=>params[:operator_id],:target=> params["target"])
     #@operator_mapping_allocation.update(operator_allocation_params)
      render json: @operator_mapping_allocation
    else
      render json: @operator_mapping_allocation.errors
    end
  end

  def operator_update
     if  @operator_mapping_allocation = OperatorMappingAllocation.update(:operator_id=>params[:operator_id],:target=> params["target"])
     #@operator_mapping_allocation.update(operator_allocation_params)
      render json: @operator_mapping_allocation
    else
      render json: @operator_mapping_allocation.errors
    end
  end


  # DELETE /operator_allocations/1
  def destroy
    if @operator_allocation.destroy
      render json: {response: @operator_allocation, status: true, msg: "Deleted successfully"}, status: :ok
    else
      render json: {response: @operator_allocation, status: false, msg: "Something went wrong"}, status: :unprocessable_entity
    end
  end


  def operator_machines
      operator_id=params["operator_id"]
      operator=OperatorAllocation.where(operator_id: operator_id).where("from_date <= ? AND to_date >= ? ", Date.today,Date.today)
      if operator.present?
         machine=Machine.where(:id=>operator.pluck(:machine_id))
         render json: machine
      else
         render json: false
      end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_operator_allocation
      @operator_allocation = OperatorAllocation.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def operator_allocation_params
      params.require(:operator_allocation).permit(:shifttransaction_id, :machine_id, :description,:tenant_id, :date, :created_by, operator_allot_details_attributes: [:id, :operation_management_id, :operator_allocation_id, :operator_id, :end_time, :start_time])
    end
end
end
end
               
