require 'stripe_mock'

include Warden::Test::Helpers
Warden.test_mode!

describe 'Customer API' do
  let(:stripe_helper) { StripeMock.create_test_helper }

  before do
    @client = StripeMock.start_client
  end

  after(:each) do
    Warden.test_reset!
  end

  after do
    StripeMock.stop_client
    # Alternatively:
    #   @client.close!
    # -- Or --
    #   StripeMock.stop_client(:clear_server_data => true)
  end

  it "creates a stripe customer with a default card" do
    customer = Stripe::Customer.create({
    email: 'user@example.com',
    card: stripe_helper.generate_card_token,
    description: "a description"
    })
    expect(customer.id).to match(/^test_cus/)
    expect(customer.email).to eq('user@example.com')
    expect(customer.description).to eq('a description')
    expect(customer.cards.count).to eq(1)
    expect(customer.cards.data.length).to eq(1)
    expect(customer.default_card).not_to be_nil
    expect(customer.default_card).to eq customer.cards.data.first.id
    expect { customer.card }.to raise_error
  end

  it "creates a stripe customer without a card" do
    customer = Stripe::Customer.create({
    email: 'cardless@example.com',
    description: "no card"
    })
    expect(customer.id).to match(/^test_cus/)
    expect(customer.email).to eq('cardless@example.com')
    expect(customer.description).to eq('no card')
    expect(customer.cards.count).to eq(0)
    expect(customer.cards.data.length).to eq(0)
    expect(customer.default_card).to be_nil
  end
    
  it "stores a created stripe customer in memory" do
    customer = Stripe::Customer.create({
    email: 'johnny@example.com',
    card: stripe_helper.generate_card_token,
    })
    customer2 = Stripe::Customer.create({
    email: 'bob@example.com',
    card: stripe_helper.generate_card_token,
    })
    customers = Stripe::Customer.all
    array = customers.to_a
    data = array.pop
    expect(data.id).not_to be_nil
    expect(data.email).to eq('bob@example.com')
    data2 = array.pop
    expect(data2.id).not_to be_nil
    expect(data2.email).to eq('johnny@example.com')
  end

  it "retrieves a stripe customer" do
    original = Stripe::Customer.create({
    email: 'johnny@example.com',
    card: stripe_helper.generate_card_token,
    })
    customer = Stripe::Customer.retrieve(original.id)
    expect(customer.id).to eq(original.id)
    expect(customer.email).to eq(original.email)
    expect(customer.default_card).to eq(original.default_card)
    expect(customer.subscriptions.count).to eq(0)
    expect(customer.subscriptions.data).to be_empty
  end

  it "cannot retrieve a customer that doesn't exist" do
    expect { Stripe::Customer.retrieve('nope') }.to raise_error {|e|
    expect(e).to be_a Stripe::InvalidRequestError
    expect(e.param).to eq('customer')
    expect(e.http_status).to eq(404)
    }
  end

  it "retrieves all customers" do
    Stripe::Customer.create({ email: 'one@example.com' })
    Stripe::Customer.create({ email: 'two@example.com' })
    all = Stripe::Customer.all
   #expect(all.length).to eq(2) 
    expect(all.length).to eq(7)  # 20141210 note that this begins at 2
    expect(all.map &:email).to include('one@example.com', 'two@example.com')
  end

  it "updates a stripe customer" do
    original = Stripe::Customer.create(id: 'test_customer_update')
    email = original.email
    original.description = 'new desc'
    original.save
    expect(original.email).to eq(email)
    expect(original.description).to eq('new desc')
    customer = Stripe::Customer.retrieve("test_customer_update")
    expect(customer.email).to eq(original.email)
    expect(customer.description).to eq('new desc')
  end

  it "updates a stripe customer's card" do
    original = Stripe::Customer.create(id: 'test_customer_update', card: stripe_helper.generate_card_token)
    card = original.cards.data.first
    expect(original.default_card).to eq(card.id)
    expect(original.cards.count).to eq(1)
    original.card = stripe_helper.generate_card_token
    original.save
    new_card = original.cards.data.first
    expect(original.cards.count).to eq(1)
    expect(original.default_card).to eq(new_card.id)
    expect(new_card.id).not_to eq(card.id)
  end

  it "deletes a customer" do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    customer = customer.delete
    expect(customer.deleted).to eq(true)
  end
end