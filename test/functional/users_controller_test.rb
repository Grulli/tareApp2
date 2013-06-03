require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, user: { admin: @user.admin, deleted: @user.deleted, email: @user.email, hashed_password: @user.hashed_password, last_login_date: @user.last_login_date, last_login_server: @user.last_login_server, lastname: @user.lastname, name: @user.name, profile: @user.profile, salt: @user.salt, session_token: @user.session_token }
    end

    assert_redirected_to user_path(assigns(:user))
  end

  test "should show user" do
    get :show, id: @user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @user
    assert_response :success
  end

  test "should update user" do
    put :update, id: @user, user: { admin: @user.admin, deleted: @user.deleted, email: @user.email, hashed_password: @user.hashed_password, last_login_date: @user.last_login_date, last_login_server: @user.last_login_server, lastname: @user.lastname, name: @user.name, profile: @user.profile, salt: @user.salt, session_token: @user.session_token }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, id: @user
    end

    assert_redirected_to users_path
  end
end
