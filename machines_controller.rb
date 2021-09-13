 module Api
  module V1
class MachinesController < ApplicationController
  before_action :set_machine, only: [:show, :update, :destroy]
  skip_before_action :authenticate_request, only: %i[api alarm_api rsmachine_data]
  include MachineHelper


  # GET /machines
  def index
    @machines = Tenant.find(params[:tenant_id]).machines
    render json: @machines
  end

  # GET /machines/1
  def show
    render json: @machine
  end

    def latest_dashboard
    machines = machine_cache
    c_shift = current_shift
    machine_list = machines.select{|i| i["tenant_id"] == params["tenant_id"].to_i}
    shifts = c_shift.select{|i| i["tenant_id"] == params["tenant_id"].to_i}
    shift = []
    shifts.each do |ll|
      case
      when ll["day"] == 1 && ll["end_day"] == 1
        duration = ll["shift_start_time"].to_time..ll["shift_end_time"].to_time
        if duration.include?(Time.now)
          shift = ll
        end
      when ll["day"] == 1 && ll["end_day"] == 2
        if Time.now.strftime("%p") == "AM"
          duration = ll["shift_start_time"].to_time-1.day..ll["shift_end_time"].to_time
         else
          duration = ll["shift_start_time"].to_time..ll["shift_end_time"].to_time+1.day
         end
        if duration.include?(Time.now)
          shift = ll
        end     
      else
        duration = ll["shift_start_time"].to_time..ll["shift_end_time"].to_time
        if duration.include?(Time.now)
          shift = ll
        end     
      end   
    end   
    # data1=MachineMonthlyLog.latest_machine_status(params)
    data1 = Dashboard.live_status(params,machine_list,shift)
    
unless data1 == 0
    running_count = []
    ff = {}
    data1.group_by{|d| d[:unit]}.map do |key1,value1|
      value={}
      value1.group_by{|i| i[:machine_status]}.map do |k,v|
        k = "waste"  if k == nil
        k = "stop"  if k == 100
        k = "running"  if k == 3
        k = "idle"  if k == 0
        k = "idle1" if k == 1
        value[k] = v.count
      end
     ff[key1] = value
    end
    render json: {"data" => data1.group_by{|d| d[:unit]}, count: ff}
  
   else
render json: {message:"No shift or Machine Currently Avaliable"}
    end
  end

   def single_machine_live_status
	   
	    machines = machine_cache
	    c_shift = current_shift
	    machine = machines.select{|i| i["id"] == params["machine_id"].to_i}.first
	    shifts = c_shift.select{|i| i["tenant_id"] == machine["tenant_id"].to_i}
	    shift = []
	    shifts.each do |ll|
	      case
	      when ll["day"] == 1 && ll["end_day"] == 1
		duration = ll["shift_start_time"].to_time..ll["shift_end_time"].to_time
		if duration.include?(Time.now)
		  shift = ll
		end
	      when ll["day"] == 1 && ll["end_day"] == 2
		if Time.now.strftime("%p") == "AM"
		  duration = ll["shift_start_time"].to_time-1.day..ll["shift_end_time"].to_time
		 else
		  duration = ll["shift_start_time"].to_time..ll["shift_end_time"].to_time+1.day
		 end
		if duration.include?(Time.now)
		  shift = ll
		end     
	      else
		duration = ll["shift_start_time"].to_time..ll["shift_end_time"].to_time
		if duration.include?(Time.now)
		  shift = ll
		end     
	      end   
	    end   

	    data1 = Dashboard.single_machine_live_status(params,machine,shift)
	    #data1=MachineMonthlyLog.single_machine_live_status(params)
	    render json: data1
	    end
	  



	  # POST /machines
	  def create
	    @machine = Machine.new(machine_params)
	 #   require 'rest-client'
	 #   RestClient.post "http://13.234.15.170/api/v1/rest_machine_create", @machine.attributes, {content_type: :json, accept: :json}


	    if @machine.save
	      @set_alarm_setting = SetAlarmSetting.create!([{:alarm_for=>"idle", :machine_id=>@machine.id},{:alarm_for=>"stop", :machine_id=>@machine.id}])
	      @machine_setting = MachineSetting.create(is_active: true, machine_id: @machine.id)
	      @machine_setting_list = MachineSettingList.create(setting_name: "x_axis", machine_setting_id: @machine_setting.id)
	      @machine_setting_list = MachineSettingList.create(setting_name: "y_axis", machine_setting_id: @machine_setting.id)
	      @machine_setting_list = MachineSettingList.create(setting_name: "z_axis", machine_setting_id: @machine_setting.id)
	      @machine_setting_list = MachineSettingList.create(setting_name: "a_axis", machine_setting_id: @machine_setting.id)
	      @machine_setting_list = MachineSettingList.create(setting_name: "b_axis", machine_setting_id: @machine_setting.id)
	     $redis.del("machine_list")
	     $redis.del("m_setting")
	     
	     render json: @machine, status: :created#, location: @machine
	    else
	      render json: @machine.errors, status: :unprocessable_entity
	    end
	  end



	 def new_board
	     #   require 'net/http'
	     #   require 'uri'

		#   http://52.66.140.40/api/v1/new_board?tenant_id=2
	    @data = MachineSetting.new_board(params)
	    render json: @data
	  end



	  def all_jobs
	    jobs = Cncjob.job_list_process(params)
	    render json: jobs
	  end

	  def dashboard_test
	    data=MachineDailyLog.dashboard_process(params)
	    render json: data
	  end

	  def dashboard_live
	    
	    data=MachineDailyLog.dashboard_process(params)
	   if data != nil
	     running_count1 = []
	  ff = {}
	  data.group_by{|d| d[:unit]}.map do |key2,value2|
	     value={}
	     value2.group_by{|i| i[:machine_status]}.map do |k,v|
	      k = "waste"  if k == nil
	      k = "stop"  if k == 100
	      k = "running"  if k == 3
	      k = "idle"  if k == 0 
	      k = "idle1" if k == 1
	      value[k] = v.count
	     end

	     
	     ff[key2] = value
	  end
	render json: {"data" => data.group_by{|d| d[:unit]}, count: ff}

	    #render json: data
	  end
	  end

	def dashboard_status_1

	  data1=MachineDailyLog.dashboard_status(params)
	  running_count = []
	  ff = {}
	  data1.group_by{|d| d[:unit]}.map do |key1,value1|
	     value={}
	     value1.group_by{|i| i[:machine_status]}.map do |k,v|
	      k = "waste"  if k == nil
	      k = "stop"  if k == 100
	      k = "running"  if k == 3
	      k = "idle"  if k == 0 
	      k = "idle1" if k == 1
	      value[k] = v.count
	     end

	     
	     ff[key1] = value
	  end
	render json: {"data" => data1.group_by{|d| d[:unit]}, count: ff}
	  
	end

	def rs_dashboard
	   data1 = MachineDailyLog.rs232_dashboard(params)
	    running_count = []
	  ff = {}
	  data1.group_by{|d| d[:unit]}.map do |key1,value1|
	     value={}
	     value1.group_by{|i| i[:machine_status]}.map do |k,v|
	      k = "waste"  if k == nil
	      k = "stop"  if k == 100
	      k = "running"  if k == 3
	      k = "idle"  if k == 0 
	      k = "idle1" if k == 1
	      value[k] = v.count
	     end

	     
	     ff[key1] = value
	  end
	render json: {"data" => data1.group_by{|d| d[:unit]}, count: ff}
	end


	def rs232_machine_process
	  data1 = MachineDailyLog.rs232_machine_process(params)
	  render json: data1
	end

	def machine_process12
	   machine=MachineDailyLog.toratex(params)
	   render json: machine
	end



	def machine_process
	   machine=MachineDailyLog.machine_process1(params)
	   render json: machine
	end

	  def machine_details
	    data = MachineLog.machine_process(params)
	    render json: data
	  end

	  def machine_counts
	   machine_data = Machine.where(:tenant_id=>params[:tenant_id]).count
	   render json: {"machine_count": machine_data}
	  end

	  
	   def hour_reports
	   
	   data =HourReport.hour_reports(params)  
	   render json: data
	   end

	   def date_reports

	   date_report = Report.date_reports(params).flatten
	   render json: date_report

	   end


	  def month_reports_wise
	   date_report1 = Report.month_reports(params).flatten
	   render json: date_report1
	  end

	  # PATCH/PUT /machines/1
	  def update
	    
	  #   @data = Machine.new(machine_params)
	 #   require 'rest-client'
	 #   RestClient.post "http://13.234.15.170/api/v1/rest_machine_update", @machine.attributes, {content_type: :json, accept: :json}

	    if @machine.update(machine_params)
	      $redis.del("machine_list")
	       $redis.del("m_setting")
	      render json: @machine
	    else
	      render json: @machine.errors, status: :unprocessable_entity
	    end
	  end

	  # DELETE /machines/1
	  def destroy
	    if @machine.destroy
	      render json: true
	    else
	      render json: false
	    end
	    # @machine.update(isactive:0)
	  end

	  def machine_log_status
	    final_data = MachineLog.stopage_time_details(params)
	    render json: final_data
	  end

	  def machine_log_status_portal
	    final_data = MachineLog.stopage_time_details_portal(params)
	    render json: final_data
	  end

	  def oee_calculation
	    oee_final = MachineLog.oee_calculation(params)
	    render json: oee_final
	  end

	#months wise csv reports
	  def month_reports
	    
	    @month_report=MachineLog.month_reports(params)
	   
	end

	  def reports_page
	    
	   @report=Report.reports(params)
	  #@report=MachineLog.reports(params).flatten
	    render json: @report
	  end

	  def hour_status

	    data = MachineLog.hour_detail(params)
	    render json: data
	  end

	  def status
	     daily_status =Machine.daily_maintanence(params)
	     render json: daily_status
	  end

	=begin  def month
	    @month_status = Machine.monthly_status(params)
	     render json: @month_status
	  end
	=end
	  def machine_log_insert
	  end

	  def part_change_summery
	    data = MachineLog.part_summery(params)
	    render json: data
	  end

	  def hour_wise_detail
	    data = MachineLog.hour_wise_status(params)
	    render json: data
	  end

	  def consolidate_data_export
	    data = ConsolidateDatum.export_data(params)
	    render json: data
	  end

	  def target_parts
	    data = MachineDailyLog.target_parts(params)
	    render json: data
	  end

	  def machine_page_status
	    
	  end
	  #####################33
	# data insert API
	def api
	  #remoe=remove_cache
	  current_prod = current_part
	  m_set = m_setting
	  machine = machine_cache
	  c_shift = current_shift

	  find_data = machine.select{|i| i['machine_ip'] == params['machine_id']}

	  if find_data.present?
	    mac_id = Machine.new(find_data.first)
	    mac_sets= m_set.select{|i| i['machine_id'] == mac_id.id}
	    if mac_sets.present?
	      mac_set = mac_sets.first
	      machine_setting = MachineSetting.new(mac_set)
	      if params["machine_status"] != '3' && params["machine_status"] != '100'
		if machine_setting.reason.present?
		  reason = machine_setting.reason
		else
		  reason = "Reason Not Entered"
		end
	      else
		reason = "Reason Not Entered"
	      end

	      axis_load = [{ "x_axis": params[:sv_x], "y_axis": params[:sv_y], "z_axis": params[:sv_z], "a_axis": params[:sv_a], "b_axis": params[:sv_b]}]
	      axis_temp = [{"x_axis": params[:svtemp_x], "y_axis": params[:svtemp_y], "z_axis": params[:svtemp_z], "a_axis": params[:svtemp_a], "b_axis": params[:svtemp_b]}]
	      puls_code = [{"x_axis": params[:svpulse_x], "y_axis": params[:svpulse_y], "z_axis": params[:svpulse_z], "a_axis": params[:svpulse_a], "b_axis": params[:svpulse_b] }]
	    
	     
	     shifts = c_shift.select{|i| i["tenant_id"] == mac_id.tenant_id}
	    shift = []
	    shifts.each do |ll|
		case
		  when ll["day"] == 1 && ll["end_day"] == 1
		    duration = ll["shift_start_time"].to_time..ll["shift_end_time"].to_time
		    if duration.include?(Time.now)
		      shift = ll
		    end
		  when ll["day"] == 1 && ll["end_day"] == 2
		    if Time.now.strftime("%p") == "AM"
		      duration = ll["shift_start_time"].to_time-1.day..ll["shift_end_time"].to_time
		     else
		      duration = ll["shift_start_time"].to_time..ll["shift_end_time"].to_time+1.day
		     end

		    #duration = ll.shift_start_time.to_time..ll.shift_end_time.to_time+1.day
		    if duration.include?(Time.now)
		      shift = ll
		    end     
		  else
		    duration = ll["shift_start_time"].to_time..ll["shift_end_time"].to_time
		    if duration.include?(Time.now)
		      shift = ll
		    end     
		  end
		  
	    end   

	      log = MachineLog.create!(machine_status: params[:machine_status],parts_count: params[:parts_count],machine_id: mac_id.id,
			  job_id: params[:job_id],total_run_time: params[:total_run_time],total_cutting_time: params[:total_cutting_time],
			  run_time: params[:run_time],feed_rate: params[:feed_rate],cutting_speed: params[:cutting_speed],
			  total_run_second:params[:total_cutting_time_second],run_second: params[:run_time_seconds],programe_number: params[:programe_number],machine_time: params[:machine_time], cycle_time_minutes: puls_code, cycle_time_per_part: reason, total_cutting_second: params[:total_cutting_time_second], spindle_load: params[:sp], x_axis: axis_load, y_axis: axis_temp, z_axis: params[:sp_temp])

	      MachineDailyLog.create!(machine_status: params[:machine_status],parts_count: params[:parts_count],machine_id: mac_id.id,
			  job_id: params[:job_id],total_run_time: params[:total_run_time],total_cutting_time: params[:total_cutting_time],
			  run_time: params[:run_time],feed_rate: params[:feed_rate],cutting_speed: params[:cutting_speed],
			  total_run_second:params[:total_cutting_time_second],run_second: params[:run_time_seconds],programe_number: params[:programe_number],machine_time: params[:machine_time], cycle_time_minutes: puls_code, cycle_time_per_part: reason, total_cutting_second: params[:total_cutting_time_second], spindle_load: params[:sp], x_axis: axis_load, y_axis: axis_temp, z_axis: params[:sp_temp])

	     unless params["machine_status"] == '100'
	      if cur_prod_data = current_prod.select{|i| i["machine_id"] == mac_id.id}.present?
		 cur_prod_data = current_prod.select{|i| i["machine_id"] == mac_id.id}.first
		 if cur_prod_data["part"] == params[:parts_count] && cur_prod_data["program_number"] == params[:programe_number]
		    unless cur_prod_data["cycle_start"].present? || params["machine_status"] != '3'
		     cyc_tym = (params["run_time"].to_i)*60 + (params["run_time_seconds"].to_i/1000)
		     CurrentPart.find(mac_id.current_part.id).update(cycle_start: Time.now, cycle_st_to_st: cyc_tym)
		     $redis.del("current_part")
		    end
		    puts "SAME PART RUNNING"
		 else
		    curr_part = CurrentPart.find(mac_id.current_part.id)
		    curr_part_st_time = curr_part.cycle_st_to_st
		    curr_part_cy_start = curr_part.cycle_start
		    curr_part.update(date: Time.now, shift_no: shift["shift_no"], part: log.parts_count, program_number: log.programe_number, cycle_time: nil, cutting_time: nil, cycle_st_to_st: nil, cycle_stop_to_stop: nil, time: nil, part_start_time: Time.now, part_end_time: Time.now, cycle_start: nil, status: 1, is_active: true, deleted_at: nil, shifttransaction_id: shift["id"])
		    last_part = Part.find(mac_id.parts.last.id)
		
		    cutt = (log.total_cutting_time.to_i * 60) + (log.total_cutting_second.to_i / 1000)
		    cutt_time = cutt - last_part.cutting_time.to_i
		    cycle_time = (log.run_time.to_i * 60) + (log.run_second.to_i / 1000)

		   
		    last_part.update(is_active: true,cutting_time: cutt_time, cycle_time: cycle_time, part_end_time: log.created_at, shift_no: shift["shift_no"],shifttransaction_id: shift["id"],cycle_st_to_st:curr_part_st_time,cycle_start:curr_part_cy_start)
		    Part.create(date: Time.now, shift_no: shift["shift_no"], part: log.parts_count, program_number: log.programe_number, cycle_time: nil, cutting_time: cutt, cycle_st_to_st: curr_part_st_time, cycle_stop_to_stop: nil, time: nil, part_start_time: Time.now, part_end_time: Time.now, cycle_start: nil, status: 1, is_active: false, deleted_at: nil, shifttransaction_id: shift["id"], machine_id: mac_id.id)
		    $redis.del("current_part")
		    # CurrentPart.find(mac_id.current_part.id).update(date: Time.now, shift_no: shift["shift_no"], part: log.parts_count, program_number: log.programe_number, cycle_time: nil, cutting_time: nil, cycle_st_to_st: nil, cycle_stop_to_stop: nil, time: nil, part_start_time: Time.now, part_end_time: Time.now, cycle_start: nil, status: 1, is_active: true, deleted_at: nil,shifttransaction_id: shift["id"])
		    
		    # last_part = Part.find(mac_id.parts.last.id)
		    # cutt = (log.total_cutting_time.to_i * 60) + (log.total_cutting_second.to_i / 1000)
		    # cutt_time = cutt - last_part.cutting_time.to_i
		    # cycle_time = (log.run_time.to_i * 60) + (log.run_second.to_i / 1000)

		    

		    # last_part.update(cutting_time: cutt_time, cycle_time: cycle_time, part_end_time: log.created_at, shift_no: shift["shift_no"],shifttransaction_id: shift["id"])
		    # Part.create(date: Time.now, shift_no: shift["shift_no"], part: log.parts_count, program_number: log.programe_number, cycle_time: nil, cutting_time: cutt, cycle_st_to_st: nil, cycle_stop_to_stop: nil, time: nil, part_start_time: Time.now, part_end_time: Time.now, cycle_start: nil, status: 1, is_active: false, deleted_at: nil, shifttransaction_id: shift["id"], machine_id: mac_id.id)
		    # $redis.del("current_part")
		 end
	      else
		if mac_id.current_part.present?
		  $redis.del("current_part")
		  current_prod = current_part
		  cur_prod_data = current_prod.select{|i| i["machine_id"] == mac_id.id}.first
		  
		  if cur_prod_data["part"] == params[:parts_count] && cur_prod_data["program_number"] == params[:programe_number] 
		    unless cur_prod_data["cycle_start"].present? || params["machine_status"] != '3'
		     cyc_tym = (params["run_time"].to_i)*60 + (params["run_time_seconds"].to_i/1000)
		     CurrentPart.find(mac_id.current_part.id).update(cycle_start: Time.now, cycle_st_to_st: cyc_tym)
		     $redis.del("current_part")
		    end
		    
		    puts "SAME PART RUNNING"

		   else
		    curr_part = CurrentPart.find(mac_id.current_part.id)
		    curr_part_st_time = curr_part.cycle_st_to_st
		    curr_part_cy_start = curr_part.cycle_start
		    curr_part.update(date: Time.now, shift_no: shift["shift_no"], part: log.parts_count, program_number: log.programe_number, cycle_time: nil, cutting_time: nil, cycle_st_to_st: nil, cycle_stop_to_stop: nil, time: nil, part_start_time: Time.now, part_end_time: Time.now, cycle_start: nil, status: 1, is_active: true, deleted_at: nil, shifttransaction_id: shift["id"])
		    last_part = Part.find(mac_id.parts.last.id)
		
		    cutt = (log.total_cutting_time.to_i * 60) + (log.total_cutting_second.to_i / 1000)
		    cutt_time = cutt - last_part.cutting_time.to_i
		    cycle_time = (log.run_time.to_i * 60) + (log.run_second.to_i / 1000)

		   
		    last_part.update(is_active: true,cutting_time: cutt_time, cycle_time: cycle_time, part_end_time: log.created_at, shift_no: shift["shift_no"],shifttransaction_id: shift["id"],cycle_st_to_st:curr_part_st_time,cycle_start:curr_part_cy_start)
		    Part.create(date: Time.now, shift_no: shift["shift_no"], part: log.parts_count, program_number: log.programe_number, cycle_time: nil, cutting_time: cutt, cycle_st_to_st: nil, cycle_stop_to_stop: nil, time: nil, part_start_time: Time.now, part_end_time: Time.now, cycle_start: nil, status: 1, is_active: false, deleted_at: nil, shifttransaction_id: shift["id"], machine_id: mac_id.id)
		    $redis.del("current_part")
		  end

		else
		  if params["machine_status"] == '3'
		    st_time = Time.now
		  end

		  cutt = (log.total_cutting_time.to_i * 60) + (log.total_cutting_second.to_i / 1000)
		  CurrentPart.create(date: Time.now, shift_no: shift["shift_no"], part: log.parts_count, program_number: log.programe_number, cycle_time: nil, cutting_time: nil, cycle_st_to_st: nil, cycle_stop_to_stop: nil, time: nil, part_start_time: Time.now, part_end_time: Time.now, cycle_start: st_time, status: 1, is_active: true, deleted_at: nil, shifttransaction_id: shift["id"], machine_id: mac_id.id)
		  Part.create(date: Time.now, shift_no: shift["shift_no"], part: log.parts_count, program_number: log.programe_number, cycle_time: nil, cutting_time: cutt, cycle_st_to_st: nil, cycle_stop_to_stop: nil, time: nil, part_start_time: Time.now, part_end_time: Time.now, cycle_start: st_time, status: 1, is_active: false, deleted_at: nil, shifttransaction_id: shift["id"], machine_id: mac_id.id)
		end
	      end
	    else
	      puts "status 100"
	    end

	      render json: "OK"
	    else
	      render json: "Machine Setting Not Registered"
	    end
	  else
	    render json: "Machine Not Registered"
	  end
	  
	 
	  






	 #render json: machine
	       
	  #  mac_id = Machine.find_by_machine_ip(params[:machine_id])

	  #  if params["machine_status"] != '3' && params["machine_status"] != '100'
	  #     if mac_id.machine_setting.reason.present?
	  #       reason = mac_id.machine_setting.reason
	  #     else
	  #       reason = "Reason Not Entered"
	  #     end
	  #  else
	  #   mac_id.machine_setting.update(reason: "Reason Not Entered")
	  #   reason = "Reason Not Entered"
	  #  end


	  #     axis_load = [{ "x_axis": params[:sv_x], "y_axis": params[:sv_y], "z_axis": params[:sv_z], "a_axis": params[:sv_a], "b_axis": params[:sv_b]}]
	  #     axis_temp = [{"x_axis": params[:svtemp_x], "y_axis": params[:svtemp_y], "z_axis": params[:svtemp_z], "a_axis": params[:svtemp_a], "b_axis": params[:svtemp_b]}]
	  #     puls_code = [{"x_axis": params[:svpulse_x], "y_axis": params[:svpulse_y], "z_axis": params[:svpulse_z], "a_axis": params[:svpulse_a], "b_axis": params[:svpulse_b] }]


	  # log = MachineLog.create!(machine_status: params[:machine_status],parts_count: params[:parts_count],machine_id: mac_id.id,
	  #               job_id: params[:job_id],total_run_time: params[:total_run_time],total_cutting_time: params[:total_cutting_time],
	  #               run_time: params[:run_time],feed_rate: params[:feed_rate],cutting_speed: params[:cutting_speed],
	  #               total_run_second:params[:total_cutting_time_second],run_second: params[:run_time_seconds],programe_number: params[:programe_number],machine_time: params[:machine_time], cycle_time_minutes: puls_code, cycle_time_per_part: reason, total_cutting_second: params[:total_cutting_time_second], spindle_load: params[:sp], x_axis: axis_load, y_axis: axis_temp, z_axis: params[:sp_temp])

	  # MachineDailyLog.create!(machine_status: params[:machine_status],parts_count: params[:parts_count],machine_id: mac_id.id,
	  #               job_id: params[:job_id],total_run_time: params[:total_run_time],total_cutting_time: params[:total_cutting_time],
	  #               run_time: params[:run_time],feed_rate: params[:feed_rate],cutting_speed: params[:cutting_speed],
	  #               total_run_second:params[:total_cutting_time_second],run_second: params[:run_time_seconds],programe_number: params[:programe_number],machine_time: params[:machine_time], cycle_time_minutes: puls_code, cycle_time_per_part: reason, total_cutting_second: params[:total_cutting_time_second], spindle_load: params[:sp], x_axis: axis_load, y_axis: axis_temp, z_axis: params[:sp_temp])
	  
	end

	  def alarm_api
	  
	    mac=Machine.find_by_machine_ip(params[:machine_id])
	      iid = mac.nil? ? 0 : mac.id
	     if mac.alarms.present?
		mac.alarms.last.update(alarm_type: params[:alarm_type],alarm_number:params[:alarm_number],alarm_message: params[:alarm_message],emergency: params[:emergency],machine_id: iid)
	     else
	       Alarm.create(alarm_type: params[:alarm_type],alarm_number:params[:alarm_number],alarm_message: params[:alarm_message],emergency: params[:emergency],machine_id: iid)
	     end



	 end
	  
	  def rsmachine_data
	     if params[:machine_id] == '192.168.1.202'
	    end
	    mac_id = Machine.find_by_machine_ip(params[:machine_id])
		MachineLog.create(machine_status: params[:machine_status],parts_count: params[:partscount].to_i,machine_id: mac_id.id,job_id: params[:job_id],total_run_time: params[:total_run_time],total_cutting_time: params[:total_cutting_time],run_time: params[:run_time],feed_rate: params[:feed_rate],cutting_speed: params[:cutting_speed],total_run_second:params[:total_cutting_time_second],run_second: params[:run_time_seconds],programe_number: params[:program_number].to_i, spindle_load: params[:sp], z_axis: params[:sp_temp])
	       MachineDailyLog.create(machine_status: params[:machine_status],parts_count: params[:partscount].to_i,machine_id: mac_id.id,job_id: params[:job_id],total_run_time: params[:total_run_time],total_cutting_time: params[:total_cutting_time],run_time: params[:run_time],feed_rate: params[:feed_rate],cutting_speed: params[:cutting_speed],total_run_second:params[:total_cutting_time_second],run_second: params[:run_time_seconds],programe_number: params[:program_number].to_i, spindle_load: params[:sp], z_axis: params[:sp_temp])

	end

	   def machine_log_history
	     #byebug
   end


  def current_trans
    
  end
   
   def shift_machine_utilization_chart
    shift_machine_utilization_chart = HourReport.shift_machine_utilization_chart(params)
    render json: shift_machine_utilization_chart
  end

  def shift_machine_status_chart
    shift_machine_status_chart = HourReport.shift_machine_status_chart(params)
    render json: shift_machine_status_chart
  end
  
  def all_cycle_time_chart_new #chat1
    all_cycle_time_chart_new = HourReport.all_cycle_time_chart_new(params)
    render json: all_cycle_time_chart_new
  end

  def all_cycle_time_chart #chat1
    all_cycle_time_chat = HourReport.all_cycle_time_chat(params)
    render json: all_cycle_time_chat
  end

  def hour_parts_count_chart #chat2
    hour_parts_count_chart = HourReport.hour_parts_count_chart(params)
    render json: hour_parts_count_chart 
  end

  def hour_machine_status_chart #chat3
    hour_machine_status_chart = HourReport.hour_machine_status_chart(params)
    render json: hour_machine_status_chart
  end

  def hour_machine_utliz_chart #chat4
    hour_machine_utliz_chart = HourReport.hour_machine_utliz_chart(params)
    render json: hour_machine_utliz_chart
  end

  def cycle_stop_to_start
    stop_to_start_chart = HourReport.cycle_stop_to_start(params)
    render json: stop_to_start_chart
  end



  ####for_test
  def hourtest
    data = Machine.single_part_report_hour(params)
    render json: data
  end

  def cycle_start_to_start
    data = HourReport.cycle_start_to_start(params)
    render json: data
  end


   def shift_part_count
    mac = Machine.find_by_machine_ip(params[:machine_ip])
    tenant = mac.tenant   
    date = Date.today.strftime("%Y-%m-%d")
    shift = Shifttransaction.current_shift(tenant.id)    
    case
      when shift.day == 1 && shift.end_day == 1   
        start_time = (date+" "+shift.shift_start_time).to_time
        end_time = (date+" "+shift.shift_end_time).to_time
        date = Date.today.strftime("%Y-%m-%d")  
      when shift.day == 1 && shift.end_day == 2
        if Time.now.strftime("%p") == "AM"
          start_time = (date+" "+shift.shift_start_time).to_time-1.day
          end_time = (date+" "+shift.shift_end_time).to_time
          date = (Date.today - 1.day).strftime("%Y-%m-%d")
        else
          start_time = (date+" "+shift.shift_start_time).to_time
          end_time = (date+" "+shift.shift_end_time).to_time+1.day
          date = Date.today.strftime("%Y-%m-%d")
        end    
      when shift.day == 2 && shift.end_day == 2
        start_time = (date+" "+shift.shift_start_time).to_time
        end_time = (date+" "+shift.shift_end_time).to_time
        date = (Date.today - 1.day).strftime("%Y-%m-%d")      
      end
    data1 = ShiftPart.where(date: date, machine_id: mac.id, shifttransaction_id: shift.id, status: nil)
#    data_count = data1.where.not(status: [1,2,3])

    render json: data1
  end

    def shift_part_update
    part = ShiftPart.find(params[:id])
    part.update(status: params[:status])
    render json: part
  end


#########################

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_machine
      @machine = Machine.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def machine_params
      params.require(:machine).permit(:machine_name, :machine_model, :machine_serial_no, :machine_type,:machine_ip, :tenant_id,:unit,:device_id, :controller_type)
    end
end
end
end
