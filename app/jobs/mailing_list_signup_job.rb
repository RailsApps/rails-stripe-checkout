class MailingListSignupJob < ActiveJob::Base
  include Celluloid
 #include SuckerPunch::Job  # causes ArgumentError: wrong number of arguments (1 for 0)

  def perform(user)
    logger.info "signing up #{user.email}"
    user.subscribe
  end

end
