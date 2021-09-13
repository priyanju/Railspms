require 'test_helper'

class ProcessPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @process_plan = process_plans(:one)
  end

  test "should get index" do
    get process_plans_url, as: :json
    assert_response :success
  end

  test "should create process_plan" do
    assert_difference('ProcessPlan.count') do
      post process_plans_url, params: { process_plan: { created_by: @process_plan.created_by, deleted_at: @process_plan.deleted_at, part_no: @process_plan.part_no, plan_name: @process_plan.plan_name, plan_number: @process_plan.plan_number, status: @process_plan.status, tenant_id: @process_plan.tenant_id } }, as: :json
    end

    assert_response 201
  end

  test "should show process_plan" do
    get process_plan_url(@process_plan), as: :json
    assert_response :success
  end

  test "should update process_plan" do
    patch process_plan_url(@process_plan), params: { process_plan: { created_by: @process_plan.created_by, deleted_at: @process_plan.deleted_at, part_no: @process_plan.part_no, plan_name: @process_plan.plan_name, plan_number: @process_plan.plan_number, status: @process_plan.status, tenant_id: @process_plan.tenant_id } }, as: :json
    assert_response 200
  end

  test "should destroy process_plan" do
    assert_difference('ProcessPlan.count', -1) do
      delete process_plan_url(@process_plan), as: :json
    end

    assert_response 204
  end
end
