module Api
  module V1
class ProgramConfsController < ApplicationController
  before_action :set_program_conf, only: [:show, :update, :destroy]
  skip_before_action :authenticate_request, only: %i[file_list]
  # GET /program_confs
  def index
    
    @machines= Tenant.find(params[:tenant_id]).machines.pluck(:id)#.select{|c| c.program_conf != nil}
     @program_confs = ProgramConf.where(machine_id: @machines)
    render json: @program_confs
  end

  # GET /program_confs/1
  def show
    render json: @program_conf
  end

  # POST /program_confs
  def create
    mac = Machine.find(params[:machine_id])
    require 'net/ssh'
    require 'net/sftp'
    if mac.present?
      # con = mac.program_conf
      begin
        Net::SFTP.start(params["ip"], params["user_name"], :password => params["pass"], :timeout => 15, :number_of_password_prompts => 0) do |sftp|
       # Net::SFTP.start('192.168.0.152', 'admin', :password => 'Yantra24x7', :number_of_password_prompts => 0) do |sftp|

          sftp.mkdir! "#{params[:master_location]}/#{mac.machine_name.split('/').last}"
          sftp.mkdir! "#{params[:master_location]}/#{mac.machine_name.split('/').last}/Master"
          sftp.mkdir! "#{params[:slave_location]}/#{mac.machine_name.split('/').last}/Slave"
          sftp.mkdir! "#{params[:master_location]}/#{mac.machine_name.split('/').last}/Backup"

          if mac.program_conf.present?
            render json: {status: "Machine already have program conf"}
          else
            @program_conf = ProgramConf.new(program_conf_params)
     
            if @program_conf.save
              # render json: @program_conf, status: :created#, location: @program_conf
              render json: {status: "File Created!!!"}
            else
              # render json: @program_conf.errors#, status: :unprocessable_entity
              render json: {status: "something went wrong"}
            end
          end
        end
      rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e 
        puts e
        if e.message.include?('authentication failed')
          render json: {status: "Authentication failures"}
        elsif e.message.include?('Too many authentication failures')
          render json: {status: 'Authentication failures'}
        elsif e.message.include?('No route to host') || e.message.include?('Authentication failed for user')
          render json: {status: "Invalid IP"}
        elsif e.message.include?('no such file')
          render json: {status: "No Such File Master or Slave"}
        #elsif e.code == 4 || e.message.include?('failure')
        elsif e.message.include?('failure')
          render json: {status: "Folder Already Exists"}
        else
          # render json: {status: "Please Contact Yantra24x7"}
          render json: {status: "Authentication failed #{e.message}"}
	end
      end
    else
      render json: {status: "Machine Not Registered"}
    end
     # # Net::SSH.start(params["ip"], params["user_name"], params["pass"]) do |ssh|
     #  Net::SSH.start('192.168.0.200', 'user', password: 'user') do |ssh|
     #    # byebug
     #    ssh.sftp.connect do |sftp|
     #      # byebug
     #      Dir.foreach('.') do |file|
     #        puts file
     #      end
     #    end 
     #  end

  # byebug

    # begin
    #   # byebug
    #   Net::SFTP.start(params["ip"], params["user_name"], :password => params["pass"], :timeout => 10, :number_of_password_prompts => 0) do |sftp|
    #       # byebug
    #     sftp.mkdir! "#{params[:master_location]}/#{mac.machine_ip}"
    #     sftp.mkdir! "#{params[:master_location]}/#{mac.machine_ip}/Master"
    #     sftp.mkdir! "#{params[:slave_location]}/#{mac.machine_ip}/Slave"

    #     @program_conf = ProgramConf.new(program_conf_params)
     
    #     if @program_conf.save
    #       render json: @program_conf, status: :created#, location: @program_conf
    #     else
    #       render json: @program_conf.errors#, status: :unprocessable_entity
    #     end
    #   end
    # # byebug
    # rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e 
    #  puts e
    #    # byebug

    #    # if e.code == 11
    #    #      # directory already exists. Carry on..
    #    #      a = 11
    #    #  elsif e.code == 2
    #    #   # render json: {status: "Ok"}
    #    #   a = 2
    #    #  else 
    #    #     a = 5
    #    #    #raise
    #    #  end

    #     if e.message.include?('authentication failed')
    #       render json: {status: "Authentication failures"}
    #     elsif e.message.include?('No route to host')
    #       render json: {status: "Invalid IP"}
    #     else
    #       render json: {status: "Please Contact yantra24x7"}
    #     end
    # end
   
  end

  def file_upload
    require 'net/sftp'
    # require 'rufus-scheduler'
    # require 'rubygems'
    # require 'rufus/scheduler'
    # require 'rake'
    mac = Machine.find(params["machine_id"])
    if mac.program_conf.present?
      con = mac.program_conf
      #scheduler = Rufus::Scheduler::PlainScheduler.start_new(:frequency => 3.0)
      # byebug 
      begin
        Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :timeout => 15, :number_of_password_prompts => 0) do |sftp|
          puts "Connection OK!"
          mas = sftp.dir.entries("#{con.master_location}/#{mac.machine_name.split('/').last}/Master").present?
          if mas == true
            sftp.upload!(params[:file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file].original_filename}") # _M#{DateTime.now}")
            path = "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file].original_filename}"
            reason = CodeCompareReason.create(user_name: params[:user_name], machine_id: params[:machine_id], new_revision_no: params[:revision_no], create_date: params[:date], old_revision_no: "-", description: "NEW UPLOADED", file_name: params[:file].original_filename)
	    render json: {status: "File Upload"}
          else
            sftp.upload!(params[:file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file].original_filename}") # _M#{DateTime.now}")
            path = "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file].original_filename}"
	    reason = CodeCompareReason.create(user_name: params[:user_name], machine_id: params[:machine_id], new_revision_no: params[:revision_no], create_date: params[:date], old_revision_no: "-", description: "NEW UPLOADED", file_name: params[:file].original_filename)
            render json: {status: "File Upload"}
          end
        end
      rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e
        unless e.message == "exit"
          #puts "Error: #{e.message}"
          if e.message.include?("authentication failures")
            render json: {status: "Authentication failed"}
          elsif e.message.include?('Authentication failed for user')
            render json: {status: "Invalid IP"}
          elsif e.message.include?("Connection refused")
            render json: {status: "Authentication failed"}
          else
            render json: {status: "Folder Not Exitst"}
          end
          #exit 2
        end
      end
    else
      render json: {status: "Machine Not Registered in File Path"}
    end
  end


  def file_upload1




    require 'net/sftp'
    # require 'rufus-scheduler'
    # require 'rubygems'
    # require 'rufus/scheduler'
    # require 'rake'
    mac = Machine.find(params["machine_id"])
    if mac.program_conf.present?
      con = mac.program_conf
      #scheduler = Rufus::Scheduler::PlainScheduler.start_new(:frequency => 3.0)
      # byebug 
      begin
        Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :timeout => 15, :number_of_password_prompts => 0) do |sftp|
          puts "Connection OK!"
         # send_data "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/sample.txt", filename: "aaa.txt"
          @data = sftp.download!("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/sample.txt")

          #sftp.download!("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/sample.txt", "D:\Projects")
          # mas = sftp.dir.entries("#{con.master_location}/#{mac.machine_name.split('/').last}/Master").present?
          # if mas == true
          #   sftp.upload!(params[:file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file].original_filename}") # _M#{DateTime.now}")
          #   reason = CodeCompareReason.create(user_id: params[:user_id], machine_id: params[:id], description: params[:reason], current_location: 1, status: false, file_path: nil) # 1 means upload
          #   render json: {status: "File Upload"}
          # else
          #   sftp.upload!(params[:file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file].original_filename}") # _M#{DateTime.now}")
          #   reason = CodeCompareReason.create(user_id: params[:user_id], machine_id: params[:id], description: params[:reason], current_location: 1, status: false, file_path: nil) # 1 means upload
          #   render json: {status: "File Upload"}
          # end
        end
      rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e
        unless e.message == "exit"
          #puts "Error: #{e.message}"
          if e.message.include?("authentication failures")
            render json: {status: "Authentication failed"}
          elsif e.message.include?('Authentication failed for user')
            render json: {status: "Invalid IP"}
          elsif e.message.include?("Connection refused")
            render json: {status: "Authentication failed"}
          else
            render json: {status: "Folder Not Exitst"}
          end
          #exit 2
        end
      end
    else
      render json: {status: "Machine Not Registered in File Path"}
    end
    send_data @data, filename: "aaa.txt"
  end


    # if mac.program_conf.present?
    #   con = mac.program_conf
    #   begin
    #     Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :timeout => 10, :number_of_password_prompts => 0) do |sftp|
    #       puts "Connection OK!"
    #       mas = sftp.dir.entries("#{con.master_location}/#{mac.machine_ip}/Master").present?
    #       slv = sftp.dir.entries("#{con.master_location}/#{mac.machine_ip}/Slave").present?
          
    #     end
    #   rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e
    #     puts e
    #     if e.message.include?('authentication failed')
    #       render json: {status: "Authentication failures"}
    #     end
    #   end
    # end



    # begin
    #   sftp.mkdir! "#{con.master_location}/#{mac.machine_ip}"
    # rescue Net::SFTP::StatusException => e
    #   # verify if this returns 11. Your server may return
    #   # something different like 4.
    #   #byebug
    #   if e.code == 11
    #     puts e.code
    #     puts e.code
    #     puts e.code
    #     puts e.code
    #   # directory already exists. Carry on..
    #   elsif e.code == 4
    #     sftp.mkdir! "#{con.master_location}/#{mac.machine_ip}/Master"
    #     sftp.mkdir! "#{con.master_location}/#{mac.machine_ip}/Slave"
    #     sftp.upload!(params[:file].path, "#{con.master_location}/#{mac.machine_ip}/Master/#{params[:file].original_filename}")
    #   else
    #     puts e.code
    #     puts e.code
    #     puts e.code
    #     raise
    #   end 
    # end


      # sftp.upload!(params[:file].path, "#{con.master_location}/#{mac.machine_ip}/Master/#{params[:file].original_filename}")
      # sftp.mkdir! "#{con.master_location}/#{mac.machine_ip}"
      # sftp.mkdir! "#{con.master_location}/#{mac.machine_ip}/Master"  
      # sftp.mkdir! "#{con.slave_location}/#{mac.machine_ip}/Slave"
      # sftp.upload!(params[:file].path, "#{con.master_location}/#{mac.machine_ip}/Master/#{params[:file].original_filename}")


# byebug
       # sftp.dir.entries(con.slave_location).partition{ |entry| entry.directory? }
      # if sftp.dir.entries(con.slave_location).present? && sftp.dir.entries(con.master_location).present?
      # else
      # end
# byebug
      #byebug
      #mas = sftp.dir.entries("#{con.master_location}/#{mac.machine_ip}/Maste").present?
      #slv = sftp.dir.entries("#{con.slave_location}/#{mac.machine_ip}/Slave").present?
# byebug
      # case [sftp.dir.entries(con.slave_location).present? , sftp.dir.entries(con.master_location).present?]
     

      # case [slv, mas]
      #   when [true, true]
      #     byebug
      #     sftp.upload!(params[:file].path, "#{mac.machine_ip}/#{con.master_location}/#{params[:file].original_filename}")
      #     render json: {status: "Ok"}
      #   when [nil, true]
      #     sftp.mkdir! "#{mac.machine_ip}/#{con.slave_location}"
      #     sftp.upload!(params[:file].path, "#{mac.machine_ip}/#{con.master_location}/#{params[:file].original_filename}")
      #     render json: {status: "Ok"}
      #   when [true, nil]
      #     sftp.mkdir! "#{mac.machine_ip}/#{con.master_location}"
      #     sftp.upload!(params[:file].path, "#{mac.machine_ip}/#{con.master_location}/#{params[:file].original_filename}")
      #     render json: {status: "Ok"}
      #   when [nil, nil]
      #     sftp.mkdir! "#{mac.machine_ip}/#{con.slave_location}"
      #     sftp.mkdir! "#{mac.machine_ip}/#{con.master_location}"
      #     sftp.upload!(params[:file].path, "#{mac.machine_ip}/#{con.master_location}/#{params[:file].original_filename}")
      #     render json: {status: "Ok"}
      # end


    #sftp.mkdir! "#{con.master_location}"
    #--- Hide For Temp ----#
    # begin
    #   sftp.upload!(params[:file].path, "#{con.master_location}/#{params[:file].original_filename}")
    #   render json: {status: "Ok"}
    # rescue Net::SFTP::StatusException => e
    #   if e.code == 11
    #     # directory already exists. Carry on..
    #   elsif e.code == 2
    #     sftp.mkdir! "#{con.master_location}"  
    #     sftp.upload!(params[:file].path, "#{con.master_location}/#{params[:file].original_filename}")
    #     render json: {status: "Ok"}
    #   else 
    #     raise
    #   end 
    # end
    #------  end -------#
   

   #  log = Logger.new('sftp.log')
   #  log.level = Logger::INFO
   #  begin
   #  log.info 'starting sftp'
   #    Net::SFTP.start(con.ip, con.user_name, :password => con.pass) do |sftp|
   #     sftp.upload!(params[:file].path, "#{con.master_location}/#{params[:file].original_filename}")
   #    end   
   #  rescue Exception => e
   #    byebug
   #    puts e.message          # Human readable error
   #    log.error ("SFTP exception occured: " + e.message)
   #  end
   # # scheduler.join
    # options = { :verbose=>:debug }
    # #Net::SFTP.start('192.168.1.244', 'root', :password => 'time') do |sftp|
    # Net::SFTP.start(con.ip, con.user_name, :password => "con.pass") do |sftp|
    #  puts "connected"
   
    #   sftp.upload!(params[:file].path, "#{con.master_location}/#{params[:file].original_filename}")
       
    # end
    # puts "Dis  connected"
     # data = sftp.download!("/media/sda1/FTP/e1.png")
        # byebug
      #sftp.upload!(user_params['file'].path, "/home/yantra/MARI/error/#{user_params['file'].original_filename}")
    

  def file_list
    @master_location = []
    @slave_location = []
    require 'net/sftp'
    if params[:id].present?
      mac = Machine.find(params["id"])
      con = mac.program_conf
      if con.present?
        begin
          # Net::SFTP.start(con.ip, con.user_name, :password => con.pass) do |sftp|
          Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :timeout => 15, :number_of_password_prompts => 0) do |sftp|
            # sftp.dir.foreach("#{con.master_location}/#{mac.machine_name.split('/').last}/Master") do |entry|
            sftp.dir.glob("#{con.master_location}/#{mac.machine_name.split('/').last}/Master", "**/*") do |entry|
              @master_location << entry
            end
            # sftp.dir.foreach("#{con.slave_location}/#{mac.machine_name.split('/').last}/Slave") do |entry1|
            sftp.dir.glob("#{con.master_location}/#{mac.machine_name.split('/').last}/Slave", "**/*") do |entry1|
              @slave_location << entry1
            end
          end
          render json: {master_location: @master_location, slave_location: @slave_location}
        rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e 
          puts e
          if e.message.include?('authentication failure')
            render json: {status: "Authentication failed"}
          elsif e.message.include?('No route to host') || e.message.include?('Authentication failed for user')
            render json: {status: "Invalid IP"}
          elsif e.message.include?('no such file') # || (e.code == 2)
            render json: {status: "No Such File Master or Slave"}
          else
	    # render json: {status: "Please Contact Yantra24x7"}
            render json: {status: "Authentication failed"}
          end
        end
      else
        # render json: {status: "This machine doesn't have program conf"}
        render json: {status: "Machine Not Registered in File Path"}
      end
    else
      render json: {status: "Give the id for machine"}
    end
  end


# ==================================================  The following two methods are written by UMA =================================================
  def file_delete
    if params[:id].present?
      mac = Machine.find(params[:id])
      con = mac.program_conf
      if con.present?
        begin
          Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :timeout => 15, :number_of_password_prompts => 0) do |sftp|
            if params[:position] == "Master"
              path = "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file_name]}"
              sftp.remove("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file_name]}").wait
              reason = CodeCompareReason.create(user_name: params[:user_name], machine_id: params[:id], description: params[:reason], create_date: params[:date], file_name: params[:file_name])
	    elsif params[:position] == "Slave"
              path = "#{con.slave_location}/#{mac.machine_name.split('/').last}/Slave/#{params[:file_name]}"
              sftp.remove("#{con.slave_location}/#{mac.machine_name.split('/').last}/Slave/#{params[:file_name]}").wait
              reason = CodeCompareReason.create(user_name: params[:user_name], machine_id: params[:id], description: params[:reason], create_date: params[:date], file_name: params[:file_name])
            end
          end
          render json: {status: "Deleted Successfully"}
        rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e 
          puts e
          if e.message.include?('authentication failure')
            render json: {status: "Authentication failed"}
          elsif e.message.include?('No route to host') || e.message.include?('Authentication failed for user')
            render json: {status: "Invalid IP"}
          elsif e.message.include?('no such file') # || (e.code == 2)
            render json: {status: "No Such File Master or Slave"}
          else
            # render json: {status: "Please Contact Yantra24x7"}
            render json: {status: "Authentication failed"}
          end
        end
      else
        # render json: {status: "This machine doesn't have program conf"}
        render json: {status: "Machine Not Registered in File Path"}
      end
    else
      render json: {status: "Select the Machine"}
    end
  end

  def file_path
    if params[:id].present?
      mac = Machine.find(params[:id])
      con = mac.program_conf
  # byebug
      if con.present?
        # if con.master_location == con.slave_location
  #      path = "#{con.ip}/#{con.master_location}/#{mac.machine_name.split('/').last}"
	 path = "#{con.ip}"
        # end
        render json: {file_path: path}, status: :ok
      else
        render json: {status: "Machine Not Registered in File Path"}
      end
    else
      render json: {status: "Please Select the Machine"}
    end
  end

  def compare_reason
    if params[:id].present?
      mac = Machine.find(params[:id])
      con = mac.program_conf
      if con.present?
        # path = "#{con.master_location}/#{mac.machine_name.split('/').last}"
        path = "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file_name]}"
        reason = CodeCompareReason.create(user_id: params[:user_id], machine_id: params[:id], description: params[:reason], current_location: 5, status: true, file_path: path) # 5 means code compare
        render json: {status: "Reason is created"}
      else
        render json: {status: "Machine Not Registered in File Path"}
      end
    else
      render json: {status: "Please Select the Machine"}
    end
  end

  def backup_file_list
    @backup_location = []
    require 'net/sftp'
    if params[:id].present?
      mac = Machine.find(params["id"])
      con = mac.program_conf
      if con.present?
        begin
          Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :timeout => 15, :number_of_password_prompts => 0) do |sftp|
            sftp.dir.glob("#{con.master_location}/#{mac.machine_name.split('/').last}/Backup", "**/*") do |entry|
              @backup_location << entry
            end
          end
          render json: {backup_location: @backup_location}
        rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e 
          puts e
          if e.message.include?('authentication failure')
            render json: {status: "Authentication failed"}
          elsif e.message.include?('No route to host') || e.message.include?('Authentication failed for user')
            render json: {status: "Invalid IP"}
          elsif e.message.include?('no such file') # || (e.code == 2)
            render json: {status: "No Such File Master or Slave"}
          else
            # render json: {status: "Please Contact Yantra24x7"}
            render json: {status: "Authentication failed"}
          end
        end
      else
        # render json: {status: "This machine doesn't have program conf"}
        render json: {status: "Machine Not Registered in File Path"}
      end
    else
      render json: {status: "Give the id for machine"}
    end
  end

  def file_download
    if params[:id].present?
      mac = Machine.find(params[:id])
      con = mac.program_conf
      if con.present?
        begin
          Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :timeout => 15, :number_of_password_prompts => 0) do |sftp|
            file_name = params[:file_name]
            if params[:position] == "Master"
              data = sftp.download!("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}")
              File.open(file_name, "wb"){|f| f << data}
              send_file( file_name, :filename => file_name )
            elsif params[:position] == "Slave"
              data = sftp.download!("#{con.slave_location}/#{mac.machine_name.split('/').last}/Slave/#{file_name}")
              File.open(file_name, "wb"){|f| f << data}
              send_file( file_name, :file_name => file_name )
            elsif params[:position] == "Backup"
              data = sftp.download!("#{con.master_location}/#{mac.machine_name.split('/').last}/Backup/#{file_name}")
              File.open(file_name, "wb"){|f| f << data}
              send_file( file_name, :file_name => file_name )
            end
          end
        rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e 
          puts e
          if e.message.include?('authentication failure')
            render json: {status: "Authentication failed"}
          elsif e.message.include?('No route to host') || e.message.include?('Authentication failed for user')
            render json: {status: "Invalid IP"}
          elsif e.message.include?('no such file') # || (e.code == 2)
            render json: {status: "No Such File Master or Slave"}
          else
            # render json: {status: "Please Contact Yantra24x7"}
            render json: {status: "Authentication failed"}
          end
        end
      else
        # render json: {status: "This machine doesn't have program conf"}
        render json: {status: "Machine Not Registered in File Path"}
      end
    else
      render json: {status: "Select the Machine"}
    end
  end


  def backup_upload
    require 'net/sftp'
    mac = Machine.find(params["machine_id"])
    if mac.program_conf.present?
      con = mac.program_conf
      begin
        Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :timeout => 15, :number_of_password_prompts => 0) do |sftp|
          puts "Connection OK!"
          mas = sftp.dir.entries("#{con.master_location}/#{mac.machine_name.split('/').last}/Backup").present?
          if mas == true
            sftp.upload!(params[:file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Backup/#{params[:file].original_filename}") # _M#{DateTime.now}")
            path = "#{con.master_location}/#{mac.machine_name.split('/').last}/Backup/#{params[:file].original_filename}"
            reason = CodeCompareReason.create(user_name: "-", machine_id: params[:machine_id], description: params[:reason], old_revision_no: "-", new_revision_no: "-", file_name: params[:file].original_filename) #user_id: params[:user_id],, current_location: 4, status: false, file_path: path) # 4 means upload from backup
            render json: {status: "File Upload"}
          else
            sftp.upload!(params[:file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Backup/#{params[:file].original_filename}") # _M#{DateTime.now}")
            path = "#{con.master_location}/#{mac.machine_name.split('/').last}/Backup/#{params[:file].original_filename}"
            reason = CodeCompareReason.create(user_name: "-", machine_id: params[:machine_id], description: params[:reason], old_revision_no: "-", new_revision_no: "-", file_name: params[:file].original_filename) #,user_id: params[:user_id],current_location: 4, status: false, file_path: path) # 4 means upload from backup
            render json: {status: "File Upload"}
          end
        end
      rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e
        unless e.message == "exit"
          #puts "Error: #{e.message}"
          if e.message.include?("authentication failures")
            render json: {status: "Authentication failed"}
          elsif e.message.include?('Authentication failed for user')
            render json: {status: "Invalid IP"}
          elsif e.message.include?("Connection refused")
            render json: {status: "Authentication failed"}
          else
            render json: {status: "Folder Not Exitst"}
          end
          #exit 2
        end
      end
    else
      render json: {status: "Machine Not Registered in File Path"}
    end
  end


    def file_move
    if params[:id].present?
      mac = Machine.find(params[:id])
      con = mac.program_conf
      if con.present?
        begin
          Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :number_of_password_prompts => 0) do |sftp|
            # file_name = params[:file_name]
              # slave_file = params[:new_file].present? ? params[:new_file] : params[:slave_file].original_filename
              slave_file = params[:slave_file].original_filename
              # slave_file1 = params[:slave_file].split("R")
              # slave_file1 = slave_file.split('R')
              slave_file1 = slave_file.split('-')

              path = "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file_name]}"
              # file_name = "#{slave_file1.first}#{slave_file1.last}"
              if slave_file1.count == 1
                file_name = "#{slave_file1.first}"
              elsif slave_file1.count == 2
                file_name = "#{slave_file1.first}"
              else
                file_name = "#{slave_file1.first.split('-').first}#{slave_file1.last}"
              end
              # file_name = "#{slave_file1.first.split('-').first}#{slave_file1.last}"
              if File.exist?(file_name)
                entries = sftp.dir.entries("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/").sort_by(&:name)
                # entries.map do |i|
                #   @file_status = i.name.include? file_name  
                # end
                @file_status = entries.map {|i| file_status = i.name.include? file_name }
                # if @file_status == true
                if @file_status.include?(true)
                  data = sftp.download!("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}")
                  write_file = File.open(file_name, "wb"){|f| f << data}
                  @open_file = File.open(write_file, 'r')
                  dir = Rails.root.join('public', 'uploads', 'Master')
                  # write_file = File.open(dir.join(file_name), 'wb') do |file|
                  File.open(dir.join(file_name), 'wb') do |file|
                    file.write(@open_file.read)
                    # file.write(@a)
                    @file_path = file.path
                  end
                  time = Time.now.strftime('%d%m%Y%H%M%S%z')
                  # backup_file = "#{slave_file1.first.split('-').first}_#{time}#{slave_file1.last}"
                  # backup_file = "#{slave_file1.first.first}_#{time}#{slave_file1.last}"
                  backup_file = "#{slave_file1.first}_#{time}"
                  upload = sftp.upload!(@file_path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Backup/#{backup_file}")
                  if upload.present?
                     file_delete = File.delete(Rails.root + @file_path)
                    if file_delete == 1
                      # sftp.remove("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}").wait
                      master_upload = sftp.upload!(params[:slave_file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}")
			puts "#{params[:slave_file].original_filename}"
                      sftp.remove("#{con.master_location}/#{mac.machine_name.split('/').last}/Slave/#{params[:slave_file].original_filename}").wait
		#	sf = File.open(slave_file, 'wb'){|f| f << data}
		#	write_data = File.open(sf, 'r')
		#	file_data = sf.read
		#	File.delete(sf)
		    else
			 master_upload = sftp.upload!(params[:slave_file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}")
                         puts "#{params[:slave_file].original_filename}"
                        sftp.remove("#{con.master_location}/#{mac.machine_name.split('/').last}/Slave/#{params[:slave_file].original_filename}").wait
                    end
                  end
                else
                  sftp.upload!(params[:slave_file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}")
		  sftp.remove("#{con.master_location}/#{mac.machine_name.split('/').last}/Slave/#{params[:slave_file].original_filename}").wait
                end
              else
                entries = sftp.dir.entries("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/").sort_by(&:name)
                # entries.map do |i|
                #   @file_status = i.name.include? file_name  
                # end
                @file_status = entries.map {|i| file_status = i.name.include? file_name }
                # if @file_status == true
                if @file_status.include?(true)
                  data = sftp.download!("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}")
                  write_file = File.open(file_name, "wb"){|f| f << data}
                  @open_file = File.open(write_file, 'r')
                  dir = Rails.root.join('public', 'uploads', 'Master')
                  # write_file = File.open(dir.join(file_name), 'wb') do |file|
                  File.open(dir.join(file_name), 'wb') do |file|
                    file.write(@open_file.read)
                    # file.write(@a)
                    @file_path = file.path
                  end
                  time = Time.now.strftime('%d%m%Y%H%M%S%z')
                  # backup_file = "#{slave_file1.first.split('-').first}_#{time}#{slave_file1.last}"
                  # backup_file = "#{slave_file1.first.first}_#{time}#{slave_file1.last}"
                  backup_file = "#{slave_file1.first}_#{time}"
                  upload = sftp.upload!(@file_path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Backup/#{backup_file}")
                  if upload.present?
                     file_delete = File.delete(Rails.root + @file_path)
                    if file_delete == 1
                      # sftp.remove("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}").wait
                      master_upload = sftp.upload!(params[:slave_file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}")
                      sftp.remove("#{con.master_location}/#{mac.machine_name.split('/').last}/Slave/#{params[:slave_file].original_filename}").wait
#			sf = File.open(slave_file, 'wb')
 #                       file_data = sf.read
  #                      File.delete(sf)
		    else
                         master_upload = sftp.upload!(params[:slave_file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}")
                         puts "#{params[:slave_file].original_filename}"
                        sftp.remove("#{con.master_location}/#{mac.machine_name.split('/').last}/Slave/#{params[:slave_file].original_filename}").wait

                    end
                  end
                else
                  sftp.upload!(params[:slave_file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}")
		  sftp.remove("#{con.master_location}/#{mac.machine_name.split('/').last}/Slave/#{params[:slave_file].original_filename}").wait
                end
                # sftp.upload!(params[:slave_file].path, "#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file_name}")
              end
              # reason = CodeCompareReason.create(user_id: params[:user_id], machine_id: params[:id], description: params[:reason], current_location: 5, status: true, file_path: path) # 5 means code compare
                   
                   reason = CodeCompareReason.create(user_name: params[:user_name], machine_id: params[:id], old_revision_no: params[:old_revision_no], new_revision_no: params[:new_revision_no], create_date: params[:date], description: params[:reason], file_name: params[:file_name])
              render json: { status: "File Moved Successfully"}
          end
        rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e 
          puts e
          if e.message.include?('authentication failure')
            render json: {status: "Authentication failed"}
          elsif e.message.include?('No route to host') || e.message.include?('Authentication failed for user')
            render json: {status: "Invalid IP"}
          elsif e.message.include?('no such file') # || (e.code == 2)
            render json: {status: "No Such File Master or Slave"}
          else
            # render json: {status: "Please Contact Yantra24x7"}
            render json: {status: "#{e.message}"}
	  end
        end
      else
        # render json: {status: "This machine doesn't have program conf"}
        render json: {status: "Machine Not Registered in File Path", file_name: "#{params[:slave_file].original_filename}"}
      end
    else
      render json: {status: "Select the Machine"}
    end
  end



  # def move_file
  #   if params[:id].present?
  #     mac = Machine.find(params[:id])
  #     con = mac.program_conf
  #     if con.present?
  #       begin
  #         # Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :timeout => 15, :number_of_password_prompts => 0) do |sftp|
  #         Net::SFTP.start(con.ip, con.user_name, :password => con.pass, :timeout => 15, :number_of_password_prompts => 0) do |sftp|
  #           if params[:position] == "Master"
  #       # byebug
  #             sftp.dir.glob("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/", params[:file_name]) do |file|
  #       # byebug
  #               sftp.download!("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{file.name}", "#{con.master_location}/#{mac.machine_name.split('/').last}/Backup/#{file.name}")

  #               path = "#{con.master_location}/#{mac.machine_name.split('/').last}/Backup/#{file.name}"
  #               reason = CodeCompareReason.create(user_id: params[:user_id], machine_id: params[:id], description: params[:reason], current_location: 3, status: false, file_path: path) # 3 for Backup
  #             end
  #               sftp.remove("#{con.master_location}/#{mac.machine_name.split('/').last}/Master/#{params[:file_name]}").wait
  #               reason = CodeCompareReason.create(user_id: params[:user_id], machine_id: params[:id], description: params[:reason], current_location: 3, status: false, file_path: nil)
                
  #              # sftp.download!("#{con.master_location}/#{mac.machine_ip}/Master/#{params[:file_name]}", "#{con.master_location}/#{mac.machine_ip}/Backup/")
  #              render json: {status: "File Successfully moved from Master to Backup"}

  #           elsif params[:position] == "Slave"
  #             sftp.dir.glob("#{con.master_location}/#{mac.machine_ip}/Slave/", params[:file_name]) do |file|
  #               sftp.download!("#{con.master_location}/#{mac.machine_ip}/Slave/#{file.name}", "#{con.master_location}/#{mac.machine_ip}/Backup/#{file.name}")
  #               path = "#{con.master_location}/#{mac.machine_ip}/Backup/#{file.name}"
  #               # reason = reason = CodeCompareReason.create(user_id: params[:user_id], machine_id: params[:id], description: params[:reason], current_location: 3, status: false, file_path: path)
  #             end
  #           end
  #             sftp.remove("#{con.master_location}/#{mac.machine_ip}/Slave/#{params[:file_name]}")
  #             # reason = CodeCompareReason.create(user_id: params[:user_id], machine_id: params[:id], description: params[:reason], current_location: 4, status: false, file_path: path)

  #             render json: {status: "File Successfully moved from Slave to Backup"}
  #         end
  #       rescue Net::SSH::Exception, Net::SFTP::Exception, SystemCallError => e 
  #         puts e
  #   # byebug
  #         if e.message.include?('authentication failure')
  #           render json: {status: "Authentication failed"}
  #         elsif e.message.include?('No route to host') || e.message.include?('Authentication failed for user')
  #           render json: {status: "Invalid IP"}
  #         elsif e.message.include?('no such file') # || (e.code == 2)
  #           render json: {status: "No Such File Master or Slave"}
  #         else
  #           render json: {status: "Please Contact Yantra24x7"}
  #         end
  #       end
  #     else
  #       render json: {status: "This Machine doesn't have program conf"}
  #     end
  #   else
  #     render json: {status: "Select the Machine"}
  #   end
  # end
# ==================================================  The above two methods are written by UMA =====================================================

  # PATCH/PUT /program_confs/1
  def update
    if @program_conf.update(program_conf_params)
      render json: @program_conf
    else
      render json: @program_conf.errors, status: :unprocessable_entity
    end
  end

  # DELETE /program_confs/1
  def destroy
    @program_conf.destroy
  end
  




  private
    # Use callbacks to share common setup or constraints between actions.
    def set_program_conf
      @program_conf = ProgramConf.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def program_conf_params
      params.require(:program_conf).permit(:ip, :user_name, :pass, :master_location, :slave_location, :machine_id)
    end
end
end
end
