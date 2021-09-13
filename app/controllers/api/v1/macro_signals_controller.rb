
 module Api
  module V1
class MacroSignalsController < ApplicationController
  before_action :set_macro_signal, only: [:show, :update, :destroy]
   skip_before_action :authenticate_request, only: %i[create]
  # GET /macro_signals
  def index
    @macro_signals = MacroSignal.all

    render json: @macro_signals
  end

  # GET /macro_signals/1
  def show
    render json: @macro_signal
  end

  # POST /macro_signals
#  def create
#    @macro_signal = MacroSignal.new(macro_signal_params)

#    if @macro_signal.save
#      render json: @macro_signal, status: :created, location: @macro_signal
#    else
#      render json: @macro_signal.errors, status: :unprocessable_entity
#    end
#  end


 def create
    time = Time.now
   machine = Machine.find_by_machine_ip(params[:machine_ip])
    if machine.present?
   
     mac_sig_value = MacroSignalOpened.where(signal: params[:signall], machine_id:  machine.id)
     if mac_sig_value.present?
       data = mac_sig_value.first
       duration = time - data.update_date
       MacroSignal.create(signal: data.signal, machine_id: machine.id, update_date: data.update_date, value: data.value, end_date: time, time_stamp: duration)
       data.update(update_date: time, value: params[:value])

       render json: true
     else
       MacroSignalOpened.create(signal: params[:signall], machine_id: machine.id, update_date: time, value: params[:value])
        render json: true
     end
    else
     render json: "Machine Not Present!!!"
    # puts "Machine Not Present!!!"
    end
  end



  # PATCH/PUT /macro_signals/1
  def update
    if @macro_signal.update(macro_signal_params)
      render json: @macro_signal
    else
      render json: @macro_signal.errors, status: :unprocessable_entity
    end
  end

  # DELETE /macro_signals/1
  def destroy
    @macro_signal.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_macro_signal
      @macro_signal = MacroSignal.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def macro_signal_params
      params.require(:macro_signal).permit(:update_date, :end_date, :time_stamp, :signal, :value, :machine_id)
    end
end
end
end
