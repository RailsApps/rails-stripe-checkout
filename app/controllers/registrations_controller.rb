class RegistrationsController < Devise::RegistrationsController

  def new
    @user = User.new
  end

  def pay
    @user = User.new
    @user.email = params[:user][:email]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    render :new
  end

  def create
    params[:user][:email] = params[:stripeEmail]
    params[:user][:stripeToken] = params[:stripeToken]
    super
  end

end
