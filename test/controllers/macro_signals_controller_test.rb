require 'test_helper'

class MacroSignalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @macro_signal = macro_signals(:one)
  end

  test "should get index" do
    get macro_signals_url, as: :json
    assert_response :success
  end

  test "should create macro_signal" do
    assert_difference('MacroSignal.count') do
      post macro_signals_url, params: { macro_signal: { end_date: @macro_signal.end_date, machine_id: @macro_signal.machine_id, signal: @macro_signal.signal, time_stamp: @macro_signal.time_stamp, update_date: @macro_signal.update_date, value: @macro_signal.value } }, as: :json
    end

    assert_response 201
  end

  test "should show macro_signal" do
    get macro_signal_url(@macro_signal), as: :json
    assert_response :success
  end

  test "should update macro_signal" do
    patch macro_signal_url(@macro_signal), params: { macro_signal: { end_date: @macro_signal.end_date, machine_id: @macro_signal.machine_id, signal: @macro_signal.signal, time_stamp: @macro_signal.time_stamp, update_date: @macro_signal.update_date, value: @macro_signal.value } }, as: :json
    assert_response 200
  end

  test "should destroy macro_signal" do
    assert_difference('MacroSignal.count', -1) do
      delete macro_signal_url(@macro_signal), as: :json
    end

    assert_response 204
  end
end
