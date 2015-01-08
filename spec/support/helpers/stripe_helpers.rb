module StripeHelpers

  require 'stripe_mock'

  describe 'StripeToken' do

    let(:stripe_helper) { StripeMock.create_test_helper }

    before do
      @client = StripeMock.start_client
    end

    after do
      StripeMock.stop_client
      # Alternatively:
      #   @client.close!
      # -- Or --
      #   StripeMock.stop_client(:clear_server_data => true)
    end
    
  describe 'create stripe token' do
    let(:stripe_helper) { StripeMock.create_test_helper }

    it "creates a stripe token" do
      stripeToken = stripe_helper.generate_card_token(:email => 'user@example.com', :amount => 995)

      # The above line replaces the following:
      # stripeToken = Stripe::Token.create(
      #   :id => 'stripe_token',
      #   :name => 'Purchase Product',
      #   :amount => 996,
      #   :currency => 'usd',
      # )
      expect(stripeToken).to match(/tok/)
     #expect(stripeToken).to eq(995)
    end
  end

  describe 'card declined error' do
#    let(:stripe_helper) { StripeMock.create_test_helper }

    it "mocks a declined card error" do
    # Prepares an error for the next create charge request
      StripeMock.prepare_card_error(:card_declined)
 
      expect { Stripe::Charge.create }.to raise_error {|e|
        expect(e).to be_a Stripe::CardError
        expect(e.http_status).to eq(402)
        expect(e.code).to eq('card_declined')
      }
      end
      
#    it "raises a custom error for specific actions" do
 #     custom_error = StandardError.new("Please knock first.")

  #    StripeMock.prepare_error(custom_error, :user)

   #   expect { Stripe::Charge.create }.not_to raise_error
    #  expect { Stripe::Customer.create }.to raise_error {|e|
     # expect(e).to be_a StandardError
      #expect(e.message).to eq("Please knock first.")
     # }
    #end
  end
end
end