module DevisePermittedParameters
  extend ActiveSupport::Concern

  included do
    before_filter :configure_permitted_parameters
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:stripeToken) }
   #devise_parameter_sanitizer.for(:sign_up) << { :email, :stripeToken }  # 20150101 commented it out : 20141216 tried it
   #devise_parameter_sanitizer.for(:sign_up) << :stripeToken               # original
   #devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :password, :password_confirmation) }
  end

end

DeviseController.send :include, DevisePermittedParameters
