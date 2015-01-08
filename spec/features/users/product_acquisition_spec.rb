include Warden::Test::Helpers
Warden.test_mode!

# Feature: Product acquisition
#   As a user
#   I want to download the product
#   So I can complete my acquisition
feature 'Product acquisition' do

  after(:each) do
    Warden.test_reset!
  end

  # Scenario: Admin User sees Welcome Admin after Sign In.
  #   Given I am an Admin user
  #   When I sign in
  #   Then I see the Welcome Admin greeting
  scenario 'Expect Admin User to sign in and see Welcome Admin' do
    user = FactoryGirl.create(:user, :admin)
    login_as(user, scope: :user)
    visit root_path
    expect(page).to have_content 'Welcome Admin'
  end

  # Scenario: Admin User sees Registered User's Count after Sign In.
  #   Given I am an Admin user
  #   When I sign in
  #   And I can see how many users we have 
  scenario 'Admin User sees number of users in database' do
    user = FactoryGirl.create(:user, :admin)
    login_as(user, scope: :user)
    visit root_path
    expect(page).to have_content 'User count:'
  end

 # Scenario: User cannot see Registered User's Count after Sign In.
  #   Given I am a registered User
  #   When I sign in
  #   Then I see the Welcome greeting
  #   But I cannot see how many users exist in the database 
  scenario 'User cannot see number of users in database' do
    user = FactoryGirl.create(:user)
    login_as(user, scope: :user)
    visit root_path
    expect(page).not_to have_content 'User count:'
  end

  # Scenario: Download the product
  #   Given I am a user
  #   When I click the 'Download' button
  #   Then I should receive a PDF file
  scenario 'Download the product' do
    user = FactoryGirl.create(:user)
    login_as(user, scope: :user)
    visit root_path
    expect(page).to have_content 'Download a free book'
    click_link_or_button 'Download PDF'
    expect(page.response_headers['Content-Type']).to have_content 'application/pdf'
  end

end
