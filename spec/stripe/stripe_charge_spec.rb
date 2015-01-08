require 'stripe_mock'

include Warden::Test::Helpers
Warden.test_mode!

describe 'Charge API' do

  let(:stripe_helper) { StripeMock.create_test_helper }

  before do
    @client = StripeMock.start_client
  end

  after(:each) do
    Warden.test_reset!
  end

  after do
    # StripeMock.stop_client
    # Alternatively:
    #   @client.close!
    # -- Or --
    StripeMock.stop_client(:clear_server_data => true)
  end

  it "requires a valid card token", :live => true do
    expect {
      charge = Stripe::Charge.create(
      amount: 995,
      currency: 'usd',
      card: 'bogus_card_token'
      )
    }.to raise_error(Stripe::InvalidRequestError, /Invalid token id/)
  end

  it "creates a stripe charge item with a card token" do
    charge = Stripe::Charge.create(
      amount: 995,
      currency: 'USD',
      card: stripe_helper.generate_card_token(last4: "4242", exp_month: 12, exp_year: 2018),
      description: 'card charge'
    )
    expect(charge.id).to match(/^test_ch/)
    expect(charge.amount).to eq(995)
    expect(charge.description).to eq('card charge')
    expect(charge.captured).to eq(true)
  end

  it "creates a stripe charge item with a customer and card id" do
    begin
    # Use Stripe's bindings...
      customer = Stripe::Customer.create({
      email: 'user@example.com',
      card: stripe_helper.generate_card_token(number: '4012888888881881'),
      description: "customer creation with card token"
    })
    expect(customer.cards.data.length).to eq(1)
    expect(customer.cards.data[0].id).not_to be_nil
    expect(customer.cards.data[0].last4).to eq('1881')
    card = customer.cards.data[0]
    charge = Stripe::Charge.create({
      amount: 995,
      currency: 'USD',
      customer: customer.id,
      card: card.id,
      description: 'a charge with a specific card'
      })
    expect(charge.amount).to eq(995)
    expect(charge.description).to eq('a charge with a specific card')
    expect(charge.captured).to eq(true)
    expect(charge.card.last4).to eq('1881')
    expect(charge.id).to match(/^test_ch/)
    rescue Stripe::CardError => e
    # Since it's a decline, Stripe::CardError will be caught
    body = e.json_body
    err = body[:error]
    puts "Status is: #{e.http_status}"
    puts "Type is: #{err[:type]}"
    puts "Code is: #{err[:code]}"
    # param is '' in this case
    puts "Param is: #{err[:param]}"
    puts "Message is: #{err[:message]}"
    rescue Stripe::InvalidRequestError => e
    # Invalid parameters were supplied to Stripe's API
    rescue Stripe::AuthenticationError => e
    # Authentication with Stripe's API failed
    # (maybe you changed API keys recently)
    rescue Stripe::APIConnectionError => e
    # Network communication with Stripe failed
    rescue Stripe::StripeError => e
    # Display a very generic error to the user, and maybe send
    # yourself an email
    rescue => e # Something else happened, completely unrelated to Stripe
end
  end

  it "retrieves a stripe charge" do
    original = Stripe::Charge.create({
      amount: 995,
      currency: 'USD',
      card: stripe_helper.generate_card_token
    })
    charge = Stripe::Charge.retrieve(original.id)
    expect(charge.id).to eq(original.id)
    expect(charge.amount).to eq(original.amount)
  end

  it "cannot retrieve a charge that doesn't exist" do
    expect { Stripe::Charge.retrieve('nope') }.to raise_error {|e|
    expect(e).to be_a Stripe::InvalidRequestError
    expect(e.param).to eq('charge')
    expect(e.http_status).to eq(404)
   }
  end

  context "retrieving a list of charges" do
    before do
      @customer = Stripe::Customer.create(email: 'user@example.com')
      @charge = Stripe::Charge.create(customer: @customer.id)
      @charge2 = Stripe::Charge.create
    end

    it "stores charges for a customer in memory" do
      expect(@customer.charges.map(&:id)).to eq([@charge.id])
    end

    it "stores all charges in memory" do
      expect(Stripe::Charge.all.map(&:id)).to eq([@charge.id, @charge2.id])
    end

    it "defaults count to 10 charges" do
      11.times { Stripe::Charge.create }
      expect(Stripe::Charge.all.count).to eq(10)
    end

    context "when passing count" do
      it "gets that many charges" do
        expect(Stripe::Charge.all(count: 1).count).to eq(1)
      end
    end
  end

describe 'captured status value' do
  it "reports captured by default" do
    charge = Stripe::Charge.create({
      amount: 995,
      currency: 'USD',
      card: stripe_helper.generate_card_token
    })
    expect(charge.captured).to eq(true)
  end

  it "reports captured if capture requested" do
    charge = Stripe::Charge.create({
      amount: 995,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      capture: true
    })
    expect(charge.captured).to eq(true)
  end
 
  it "reports not captured if capture: false requested" do
    charge = Stripe::Charge.create({
      amount: 995,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      capture: false
    })
    expect(charge.captured).to eq(false)
  end
end

describe "two-step charge (auth, then capture)" do
  it "changes captured status upon #capture" do
    charge = Stripe::Charge.create({
       amount: 995,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      capture: false
    })
    returned_charge = charge.capture
    expect(charge.captured).to eq(true)
    expect(returned_charge.id).to eq(charge.id)
    expect(returned_charge.captured).to eq(true)
  end

  it "captures with specified amount" do
    charge = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      capture: false
    })
    returned_charge = charge.capture({ amount: 677 })
    expect(charge.captured).to eq(true)
    expect(returned_charge.amount_refunded).to eq(100)
    expect(returned_charge.id).to eq(charge.id)
    expect(returned_charge.captured).to eq(true)
  end
end

  it "retrieves an empty list if there's no subscriptions" do
    Stripe::Customer.create(id: 'no_cards')
    customer = Stripe::Customer.retrieve('no_cards')
    list = customer.cards.all
    expect(list.object).to eq("list")
    expect(list.count).to eq(0)
    expect(list.data.length).to eq(0)
  end

end
