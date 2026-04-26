# frozen_string_literal: true

require "rails_helper"

# Request-level guard for the mobile header markup (Capybara/Cuprite is optional in dev).
RSpec.describe "Mobile application header" do
  it "renders the mobile menu shell and a Tickets link for signed-in users" do
    user = create(:user)
    sign_in user
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("data-controller=\"mobile-nav\"")
    expect(response.body).to include("id=\"mobile-nav-panel\"")
    # Desktop main nav and mobile column both link to tickets.
    expect(response.body.scan(Regexp.escape(tickets_tickets_path)).size).to be >= 2
  end

  it "renders guest sign-in and sign up in the mobile block" do
    get root_path
    expect(response).to have_http_status(:ok)
    body = response.body
    i = body.index("id=\"mobile-nav-panel\"")
    expect(i).to be_a(Integer)
    slice = body[i, 1_200]
    expect(slice).to include("Sign in")
    expect(slice).to include("Sign up")
  end
end
