# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home dashboard", type: :system do
  it "shows a resident's property, ticket, and link to the tickets list" do
    resident = create(:user, first_name: "Rae", last_name: "Resident")
    property = create(:property, name: "Sunset View 1A")
    create(:membership, user: resident, property: property)
    create(:ticket, user: resident, property: property, subject: "Gate not closing", status: :open)
    create(:document, title: "Parking policy", category: :policy, uploaded_by: create(:user, :board))
    sign_in resident

    visit root_path

    expect(page).to have_content("Sunset View 1A")
    expect(page).to have_content("Gate not closing")
    expect(page).to have_content("Parking policy")
    expect(page).to have_link("View all tickets", href: tickets_tickets_path)

    click_link "View all tickets"
    expect(page).to have_current_path(tickets_tickets_path)
  end

  it "navigates to documents from the resident library link" do
    resident = create(:user)
    create(:document, title: "Noise policy", uploaded_by: create(:user, :board))
    sign_in resident

    visit root_path
    expect(page).to have_link("Library", href: documents_path)

    click_link "Library"
    expect(page).to have_current_path(documents_path)
  end

  it "lets a board member see the staff dashboard and open tickets" do
    p1 = create(:property, name: "Cedar Lane")
    create(
      :ticket,
      user: create(:user, :resident, first_name: "Pat"),
      property: p1,
      subject: "Patio inspection request",
      status: :in_progress
    )
    sign_in create(:user, :board, first_name: "Boardy", last_name: "Member")

    visit root_path
    expect(page).to have_content("Community overview")
    expect(page).to have_content("1 open or in progress")
    expect(page).to have_content("Patio inspection request")
    expect(page).to have_content("Pat")
  end

  it "shows the treasurer callout to treasurers" do
    sign_in create(:user, :treasurer, first_name: "Terry")

    visit root_path

    expect(page).to have_content("Accounting & reporting")
    expect(page).to have_link("Dues aging", href: accounting_reports_dues_aging_path)
  end

  it "does not show the staff accounting strip to board members" do
    sign_in create(:user, :board)

    visit root_path

    expect(page).to have_content("Support tickets")
    expect(page).to have_no_content("Accounting & reporting")
  end
end
