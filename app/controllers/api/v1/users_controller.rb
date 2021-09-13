module Api
  module V1
class UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy, :reset_password]
  skip_before_action :authenticate_request, only: %i[email_validation check_status reset_password]
   
  # GET /users
  def index
#    users = User.where(tenant_id:params[:tenant_id]).where.not(role_id:1)
#    users = User.where(tenant_id: @current_user.tenant_id).where.not(id: @current_user.tenant_id)
     users = User.where(tenant_id: @current_user.tenant_id)
    #users = Tenant.find(params[:tenant_id]).users.where.not(role_id:Tenant.find(params[:tenant_id]).roles.where(role_name:"CEO")[0].id)
    render json: users
  end

  def check_status
    if Tenant.all.present?
        status = true
       else
        status = false
       end
       render json: status
  end

  # GET /users/1
  def show
    render json: @user
  end
  
  def reset_password
        if @user.present?
                @user.update(password_digest: params[:password_digest],password: params[:password],default: params[:password])
                render json: {status: true, msg:"Password changed successfully"}, status: :ok
                else
                render json: {status: false}, status: :ok

        end
  end


  # POST /users
  def create
   # @user = User.new(user_params)
    # @user = User.new(first_name: params[:first_name], last_name: params[:last_name], email_id: params[:email_id], password: params[:password], phone_number: params[:phone_number], remarks: params[:remarks], usertype_id: params[:usertype_id], approval_id: params[:approval_id], tenant_id: params[:tenant_id], role_id: params[:role_id],isactive: true)
  @user_data = {first_name: params[:first_name], last_name: params[:last_name], email_id: params[:email_id], password: params[:password], phone_number: params[:phone_number], remarks: params[:remarks], usertype_id: params[:usertype_id], tenant_id:params[:tenant_id], role_id:params[:role_id], default: params[:password],isactive: true}    
  @user = User.new(first_name: params[:first_name], last_name: params[:last_name], email_id: params[:email_id], password: params[:password], phone_number: params[:phone_number], remarks: params[:remarks], usertype_id: params[:usertype_id], tenant_id:params[:tenant_id], role_id:params[:role_id],default: params[:password], isactive: true)
   
#   require 'rest-client'
#    RestClient.post "http://13.234.15.170/api/v1/rest_user_create", @user_data, {content_type: :json, accept: :json}    



    if @user.save
      render json: {response: @user, status: true, msg: "User created Successfully"}, status: :ok#@user, status: :created#, location: @user
    else
      render json: {response: @user, status:false, msg: "Email_id has already taken"}, status: :ok
    end
  end

  def pending_approvals
    # all_users = User.approval_pending
    # render json: all_users
   data = Tenant.where(isactive: [nil, false])
   render json: data
  end

  # PATCH/PUT /users/1
  def update

    puts params    
    @user_data = {id: params[:id], first_name: params[:first_name], last_name: params[:last_name], email_id: params[:email_id],  phone_number: params[:phone_number], remarks: params[:remarks], usertype_id: params[:usertype_id], tenant_id:params[:tenant_id], role_id:params[:role_id], default: params[:password],isactive: true, password: params[:password]}
 
 #   require 'rest-client'
 #   RestClient.post "http://13.234.15.170/api/v1/rest_user_update", @user_data, {content_type: :json, accept: :json}

    if @user.update(user_params)
      @user.update(isactive: true)
#      ApprovalMailer.approval_user(@user).deliver
       render json: {response: @user, status: true, msg: "Updated Successfully"}, status: :ok
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

   def approval_list
    role = Role.where(role_name: "CEO").ids

    user = User.includes(:tenant).where(role_id: role, isactive: nil)
   # user = User.where(isactive: nil)
     render json: user
   end


  # DELETE /users/1
  def destroy
    if @user.destroy
	render json: true
    else
	render json: false
    end
    #@user.update(isactive:0)
	
  end

    def admin_user
    @users = User.where(usertype_id: 2)
    render json: @users
  end

  def email_validation
      result=User.email_validation(params)
      render json: result
  end
  

  def password_recovery
    password = User.find_by(email_id:params[:email_id]).present? ? User.find_by(email_id:params[:email_id]).password : false
    
    password = {"password": password}
    render json: password
  end
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def user_params
      params.require(:user).permit(:first_name, :last_name, :email_id, :password, :phone_number, :remarks, :usertype_id, :approval_id, :tenant_id, :role_id,:isactive,:default)
    end
end
end
end
