# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home dashboard" do
  describe "GET /" do
    it "renders the treasurer callout (accounting & reporting) for treasurers" do
      user = create(:user, :treasurer)
      sign_in user
      get root_path

      expect(response.body).to include("Accounting &amp; reporting")
      expect(response.body).to include("Dues aging")
    end

    it "does not show the admin-only callout to treasurers" do
      user = create(:user, :treasurer)
      sign_in user
      get root_path

      expect(response.body).not_to include("Administration")
    end

    it "renders the treasurer and admin callouts for admins" do
      user = create(:user, :admin)
      sign_in user
      get root_path

      expect(response.body).to include("Accounting &amp; reporting")
      expect(response.body).to include("Administration")
      expect(response.body).to include("Add property")
    end

    it "does not render the treasurer or admin callouts for board (staff) members" do
      user = create(:user, :board)
      sign_in user
      get root_path

      expect(response.body).to include("Support tickets")
      expect(response.body).not_to include("Accounting &amp; reporting")
      expect(response.body).not_to include("Administration")
    end

    it "renders a resident's properties, tickets, documents, and dues" do
      resident = create(:user, first_name: "Rae", last_name: "Resident")
      property = create(:property, name: "Sunset View 1A")
      create(:membership, user: resident, property: property)
      create(:ticket, user: resident, property: property, subject: "Gate code not working", status: :open)
      create(:dues_assessment, property: property, description: "Q1 dues", status: :open, due_date: 1.week.from_now)
      create(:document, title: "Community pool rules 2024", category: :policy, uploaded_by: create(:user, :board))
      sign_in resident

      get root_path

      expect(response.body).to include("Sunset View 1A")
      expect(response.body).to include("Gate code not working")
      expect(response.body).to include("Community pool rules 2024")
      expect(response.body).to include("Dues &amp; payments")
    end

    it "shows overdue dues for the resident's properties" do
      resident = create(:user)
      property = create(:property)
      create(:membership, user: resident, property: property)
      create(:dues_assessment, :overdue, property: property)
      sign_in resident

      get root_path

      expect(response.body).to include("1 overdue")
    end

    it "does not include another resident's ticket" do
      alice = create(:user, first_name: "Alice")
      bob   = create(:user, first_name: "Bob")
      create(:ticket, user: bob, subject: "Bobs private ticket subject 9911")
      sign_in alice
      get root_path

      expect(response.body).not_to include("Bobs private ticket subject 9911")
    end

    it "lets staff see tickets from all residents" do
      alice = create(:user, :resident, first_name: "Alice")
      create(:property)
      p2 = create(:property)
      create(:ticket, user: alice, subject: "Alices ticket 7722")
      create(:ticket, user: create(:user, first_name: "Zed"), property: p2, subject: "Zeds ticket 3344")
      board = create(:user, :board)
      sign_in board
      get root_path

      expect(response.body).to include("Alices ticket 7722")
      expect(response.body).to include("Zeds ticket 3344")
    end
  end
end
