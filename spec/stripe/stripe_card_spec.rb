require 'stripe_mock'

include Warden::Test::Helpers
Warden.test_mode!

describe 'StripeToken' do
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
    
  it 'creates/returns a card when using customer.cards.create given a card token' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    card_token = StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
    card = customer.cards.create(card: card_token)
    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("1123")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(2099)
    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.cards.count).to eq(1)
    card = customer.cards.data.first
    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("1123")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(2099)
  end

  it 'creates/returns a card when using customer.cards.create given card params' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    card = customer.cards.create(card: {
      number: '4242424242424242',
      exp_month: '11',
      exp_year: '3031',
      cvc: '123'
    })
    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("4242")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(3031)
    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.cards.count).to eq(1)
    card = customer.cards.data.first
    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("4242")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(3031)
  end

  it "creates a single card with a generated card token", :live => true do
    customer = Stripe::Customer.create
    expect(customer.cards.count).to eq 0
    customer.cards.create :card => stripe_helper.generate_card_token
    # Yes, stripe-ruby does not actually add the new card to the customer instance
    expect(customer.cards.count).to eq 0
    customer2 = Stripe::Customer.retrieve(customer.id)
    expect(customer2.cards.count).to eq 1
    expect(customer2.default_card).to eq customer2.cards.first.id
  end

  it 'create does not change the customers default card if already set' do
    customer = Stripe::Customer.create(id: 'test_customer_sub', default_card: "test_cc_original")
    card_token = StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
    card = customer.cards.create(card: card_token)
    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.default_card).to eq("test_cc_original")
  end

  it 'create updates the customers default card if not set' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    card_token = StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
    card = customer.cards.create(card: card_token)
    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.default_card).not_to be_nil
  end

  context "retrieval and deletion" do
    let!(:customer) { Stripe::Customer.create(id: 'test_customer_sub') }
    let!(:card_token) { StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099) }
    let!(:card) { customer.cards.create(card: card_token) }
    it "retrieves a customers card" do
    retrieved = customer.cards.retrieve(card.id)
    expect(retrieved.to_s).to eq(card.to_s)
    end
    it "retrieves a customer's card after re-fetching the customer" do
    retrieved = Stripe::Customer.retrieve(customer.id).cards.retrieve(card.id)
    expect(retrieved.id).to eq card.id
    end
    it "deletes a customers card" do
    card.delete
    retrieved_cus = Stripe::Customer.retrieve(customer.id)
    expect(retrieved_cus.cards.data).to be_empty
    end
    it "deletes a customers card then set the default_card to nil" do
    card.delete
    retrieved_cus = Stripe::Customer.retrieve(customer.id)
    expect(retrieved_cus.default_card).to be_nil
    end
    it "updates the default card if deleted" do
    card.delete
    retrieved_cus = Stripe::Customer.retrieve(customer.id)
    expect(retrieved_cus.default_card).to be_nil
    end
    context "deletion when the user has two cards" do
    let!(:card_token_2) { StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099) }
    let!(:card_2) { customer.cards.create(card: card_token_2) }
    it "has just one card anymore" do
    card.delete
    retrieved_cus = Stripe::Customer.retrieve(customer.id)
    expect(retrieved_cus.cards.data.count).to eq 1
    expect(retrieved_cus.cards.data.first.id).to eq card_2.id
    end
    it "sets the default_card id to the last card remaining id" do
    card.delete
    retrieved_cus = Stripe::Customer.retrieve(customer.id)
    expect(retrieved_cus.default_card).to eq card_2.id
    end
    end
    end
    describe "Errors", :live => true do
    it "throws an error when the customer does not have the retrieving card id" do
    customer = Stripe::Customer.create
    card_id = "card_123"
    expect { customer.cards.retrieve(card_id) }.to raise_error {|e|
    expect(e).to be_a Stripe::InvalidRequestError
    expect(e.message).to include "Customer", customer.id, "does not have", card_id
    expect(e.param).to eq 'card'
    expect(e.http_status).to eq 404
    }
    end
  end

  context "update card" do
    let!(:customer) { Stripe::Customer.create(id: 'test_customer_sub') }
    let!(:card_token) { stripe_helper.generate_card_token(last4: "4242", exp_month: 11, exp_year: 2019) }
    let!(:card) { customer.cards.create(card: card_token) }
 
    it "updates the card" do
      exp_month = 10
      exp_year = 2020

      card.exp_month = exp_month
      card.exp_year = exp_year
      card.save

      retrieved = customer.cards.retrieve(card.id)
      expect(retrieved.exp_month).to eq(exp_month)
      expect(retrieved.exp_year).to eq(exp_year)
    end
  end

  context "retrieve multiple cards" do
    it "retrieves a list of multiple cards" do
      customer = Stripe::Customer.create(id: 'test_customer_card')
      card_token = StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
      card1 = customer.cards.create(card: card_token)
      card_token = StripeMock.generate_card_token(last4: "1124", exp_month: 12, exp_year: 2098)
      card2 = customer.cards.create(card: card_token)
      customer = Stripe::Customer.retrieve('test_customer_card')
      list = customer.cards.all
      expect(list.object).to eq("list")
      expect(list.count).to eq(2)
      expect(list.data.length).to eq(2)
      expect(list.data.first.object).to eq("card")
      expect(list.data.first.to_hash).to eq(card1.to_hash)
      expect(list.data.last.object).to eq("card")
      expect(list.data.last.to_hash).to eq(card2.to_hash)
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
