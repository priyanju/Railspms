module Api
  module V1
class ShifttransactionsController < ApplicationController
  before_action :set_shifttransaction, only: [:show, :update, :destroy]

  # GET /shifttransactions
  def index
    if params[:shift_id] == 'undefined'
    render json: []
    else
    @shifttransactions = Shift.find(params[:shift_id]).shifttransactions
    render json: @shifttransactions
    end
  end

  # GET /shifttransactions/1
  def show
    render json: @shifttransaction
  end
  
  def show_shift
	shift = Shifttransaction.get_all_shift(params)
        render json: shift	
  end

  # POST /shifttransactions
  def create

     @shifttransaction = Shifttransaction.new(shifttransaction_params)
      all_shift = []
      shifts = Shifttransaction.all
      shifts.map do |ll|
      case
      when ll.day == 1 && ll.end_day == 1
        all_shift << [ll.shift_start_time.to_time..ll.shift_end_time.to_time]
      when ll.day == 1 && ll.end_day == 2
        all_shift <<  [ll.shift_start_time.to_time..ll.shift_end_time.to_time+1.day]
      else
        all_shift << [ll.shift_start_time.to_time+1.day..ll.shift_end_time.to_time+1.day]
      end
     end
     if @shifttransaction.day == 1 && @shifttransaction.end_day== 1
       start_time = @shifttransaction.shift_start_time.to_time
       end_time = @shifttransaction.shift_end_time.to_time
     elsif @shifttransaction.day == 1 && @shifttransaction.end_day== 2
       start_time = @shifttransaction.shift_start_time.to_time
       end_time = @shifttransaction.shift_end_time.to_time+1.day
     else
       shift_time = @shifttransaction.shift_start_time.to_time+1.day
       end_time = @shifttransaction.shift_end_time.to_time+1.day
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
render json: {msg: "Please enter correct start time or end time"}
else
   
#    @shifttransaction.actual_working_hours = params[:shift_start_time].to_time.strftime("%p")=="PM" && params[:shift_end_time].to_time.strftime("%p")=="AM" ?  Time.at((params[:shift_end_time].to_time - 1.day) - params[:shift_start_time].to_time).utc.strftime("%H:%M:%S") : Time.at(params[:shift_end_time].to_time - params[:shift_start_time].to_time).utc.strftime("%H:%M:%S")      
      @shifttransaction.break_time = (Time.parse(params[:break_time]).seconds_since_midnight).to_s
      full_working_hour = (params[:shift_end_time].to_time - params[:shift_start_time].to_time).to_i
      @shifttransaction.actual_working_hours = (full_working_hour - (@shifttransaction.break_time).to_i).to_s
#     @shifttransaction.actual_working_without_break = @shifttransaction.actual_working_hours
#     @shifttransaction.actual_working_hours_dummy = 
  #   @shifttransaction.shift_start_time_dummy = (Time.parse(params[:shift_start_time_dummy]).seconds_since_midnight).to_i
   #  @shifttransaction.shift_end_time_dummy = (Time.parse(params[:shift_end_time_dummy]).seconds_since_midnight).to_i
    if @shifttransaction.save
      render json: {status: true, msg: "Created Successfully", data: @shifttransaction}, status: :ok#@shifttransaction, status: :created#, location: @shifttransaction
    else
      render json: {status: false, msg: "shift_no has already present"}, status: :ok#@shifttransaction.errors, status: :unprocessable_entity
    end
  end
end
  # PATCH/PUT /shifttransactions/1
  def update
     
    if @shifttransaction.update(shifttransaction_params)
      actual_working_hours =params[:shift_start_time].to_time.strftime("%p")=="PM" && params[:shift_end_time].to_time.strftime("%p")=="AM" ?  Time.at((params[:shift_end_time].to_time - 1.day) - params[:shift_start_time].to_time).utc.strftime("%H:%M:%S") : Time.at(params[:shift_end_time].to_time - params[:shift_start_time].to_time).utc.strftime("%H:%M:%S") 
      @shifttransaction.update(actual_working_hours:actual_working_hours)
       $redis.del("current_shift")
      render json: {response: @shifttransaction, status: true, msg: "Updated Successfully"}, status: :ok
    else
      render json: @shifttransaction.errors, status: :unprocessable_entity
    end
  end

  # DELETE /shifttransactions/1
  def destroy
    @shifttransaction.destroy
    if @shifttransaction.destroy
      render json: true
    else
      render json: false
    end
    #@shifttransaction.update(isactive:0)
  end

  def get_all_shift
    shift = Shifttransaction.get_all_shift(params)
    render json: shift
  end

  def find_shift
    data = Shifttransaction.find_shift(params)
    render json: data
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shifttransaction
      @shifttransaction = Shifttransaction.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def shifttransaction_params
      params.require(:shifttransaction).permit!
    end
end
end
end
