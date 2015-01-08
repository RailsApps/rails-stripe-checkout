class MailingListSignupJob < ActiveJob::Base
  include Celluloid        # 20141228
# include SuckerPunch::Job # 20141228

  def perform(user)
    logger.info "signing up #{user.email}"
    user.subscribe
  end

end
