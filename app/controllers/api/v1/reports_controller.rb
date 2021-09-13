module Api
 module V1
  class ReportsController < ApplicationController
   def machine_job_report
     machine_job_reports = Machine.machine_job_report(params)
     render json: machine_job_reports
   end
   def idle_report
                          #
    machine = params[:machine]#Machine.where(id: params[:machine_id]).ids
    st_time = params[:date].present? ? params[:date].split('-')[0] : (Date.today - 1).strftime('%m/%d/%Y')
    date = Date.strptime(st_time, '%m/%d/%Y')

      # date = params[:date].to_date.strftime("%Y-%m-%d")
    shift = params[:shift]#Shifttransaction.where(id:params[:shift_id]).pluck(:shift_no)
#       byebug
#       idle_report = IdleReasonActive.where(date:  date.to_time.strftime("%m-%d-%Y"), shift_no: shift, machine_name: machine)
     idle_report = IdleReasonActive.where(date:  date, shift_no: shift, machine_id: machine)
     render json: idle_report
  #  data = CncHourReport.where(date: date, machine_id: machine, shift_no: shift)
                         
   end
end
end
end
