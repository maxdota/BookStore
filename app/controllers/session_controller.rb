class SessionController < ApplicationController
  skip_before_filter :user_authorize, :admin_authorize
  include SimpleCaptcha::ControllerHelpers
  
  def new
  end
  
  def create    
    if !session[:fail_attemp] || session[:fail_attemp] < 3 || simple_captcha_valid?
      user = User.find_by_username(params[:username])
      if !user || !user.authenticate(params[:password])
        fail_attemp_add
        redirect_to login_url, :alert => "Invalid username/password combination."
      elsif !user.activation
        session[:fail_attemp] = nil
        redirect_to login_url, :alert => "Please activate your account. Contact an admin if you can't get the activation email in your inbox"      
      else
        session[:fail_attemp] = nil
        session[:user_id] = user.id
        session[:role] = user.role
        redirect_to store_url, :notice => "Welcome, #{user.username} (#{session[:role]} role)"
      end
    else
      redirect_to login_url, :alert => "The letters you entered does not match the image."
    end
  end

  def destroy
    session[:user_id] = nil
    session[:role] = nil
    redirect_to store_url, :notice => "Logged out successfully."
  end

  def fail_attemp_add
    if session[:fail_attemp]
      session[:fail_attemp] += 1
    else
      session[:fail_attemp] = 1
    end
  end
end