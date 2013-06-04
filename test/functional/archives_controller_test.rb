require 'test_helper'

class ArchivesControllerTest < ActionController::TestCase
  setup do
    @archive = archives(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:archives)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create archive" do
    assert_difference('Archive.count') do
      post :create, archive: { ip: @archive.ip, name: @archive.name, participation_id: @archive.participation_id, version: @archive.version }
    end

    assert_redirected_to archive_path(assigns(:archive))
  end

  test "should show archive" do
    get :show, id: @archive
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @archive
    assert_response :success
  end

  test "should update archive" do
    put :update, id: @archive, archive: { ip: @archive.ip, name: @archive.name, participation_id: @archive.participation_id, version: @archive.version }
    assert_redirected_to archive_path(assigns(:archive))
  end

  test "should destroy archive" do
    assert_difference('Archive.count', -1) do
      delete :destroy, id: @archive
    end

    assert_redirected_to archives_path
  end
end
