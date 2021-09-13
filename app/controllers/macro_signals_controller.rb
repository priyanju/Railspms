class MacroSignalsController < ApplicationController
  before_action :set_macro_signal, only: [:show, :update, :destroy]

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
  def create
    @macro_signal = MacroSignal.new(macro_signal_params)

    if @macro_signal.save
      render json: @macro_signal, status: :created, location: @macro_signal
    else
      render json: @macro_signal.errors, status: :unprocessable_entity
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
