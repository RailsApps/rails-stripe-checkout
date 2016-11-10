class User < ApplicationRecord
  enum role: [:user, :vip, :admin]
  after_initialize :set_default_role, :if => :new_record?
  before_create :pay_with_card, unless: Proc.new { |user| user.admin? }
  after_create :sign_up_for_mailing_list

  attr_accessor :stripeToken

  def set_default_role
    self.role ||= :user
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def pay_with_card
    if self.stripeToken.nil?
      self.errors[:base] << 'Could not verify card.'
      raise ActiveRecord::RecordInvalid.new(self)
    end
    customer = Stripe::Customer.create(
      :email => self.email,
      :card  => self.stripeToken
    )
    price = Rails.application.secrets.product_price
    title = Rails.application.secrets.product_title
    charge = Stripe::Charge.create(
      :customer    => customer.id,
      :amount      => "#{price}",
      :description => "#{title}",
      :currency    => 'usd'
    )
    Rails.logger.info("Stripe transaction for #{self.email}") if charge[:paid] == true
  rescue Stripe::InvalidRequestError => e
    self.errors[:base] << e.message
    raise ActiveRecord::RecordInvalid.new(self)
  rescue Stripe::CardError => e
    self.errors[:base] << e.message
    raise ActiveRecord::RecordInvalid.new(self)
  end

  def sign_up_for_mailing_list
    MailingListSignupJob.perform_later(self)
  end

  def subscribe
    mailchimp = Gibbon::Request.new(api_key: Rails.application.secrets.mailchimp_api_key)
    list_id = Rails.application.secrets.mailchimp_list_id
    result = mailchimp.lists(list_id).members.create(
      body: {
        email_address: self.email,
        status: 'subscribed'
    })
    Rails.logger.info("Subscribed #{self.email} to MailChimp") if result
  end

end
