# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tickets::Tickets" do
  let(:admin) { create(:user, :admin) }
  let(:resident) { create(:user) }
  let(:other_resident) { create(:user) }

  describe "GET /tickets" do
    it "requires authentication" do
      get tickets_tickets_path
      expect(response).to redirect_to(new_user_session_path)
    end

    { "admin" => :admin, "board member" => :board, "treasurer" => :treasurer }.each do |label, trait|
      it "shows all tickets to #{label}" do
        create(:ticket, subject: "First ticket", user: resident)
        create(:ticket, subject: "Second ticket", user: other_resident)

        sign_in create(:user, trait)
        get tickets_tickets_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("First ticket")
        expect(response.body).to include("Second ticket")
      end
    end

    it "shows only own tickets to residents" do
      create(:ticket, subject: "My ticket", user: resident)
      create(:ticket, subject: "Not mine", user: other_resident)

      sign_in resident
      get tickets_tickets_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My ticket")
      expect(response.body).not_to include("Not mine")
    end

    it "filters by status" do
      create(:ticket, subject: "Open one", user: resident)
      create(:ticket, :closed, subject: "Closed one", user: resident)

      sign_in resident
      get tickets_tickets_path(status: "open")
      expect(response.body).to include("Open one")
      expect(response.body).not_to include("Closed one")
    end

    it "filters by category" do
      create(:ticket, subject: "Landscaping issue", user: resident, category: :landscaping)
      create(:ticket, subject: "Parking issue", user: resident, category: :parking)

      sign_in resident
      get tickets_tickets_path(category: "landscaping")
      expect(response.body).to include("Landscaping issue")
      expect(response.body).not_to include("Parking issue")
    end

    it "filters by priority" do
      create(:ticket, subject: "Urgent work", user: resident, priority: :urgent)
      create(:ticket, subject: "Low priority item", user: resident, priority: :low)

      sign_in resident
      get tickets_tickets_path(priority: "urgent")
      expect(response.body).to include("Urgent work")
      expect(response.body).not_to include("Low priority item")
    end

    describe "filter by created date" do
      it "applies created_on_or_after" do
        create(:ticket, user: resident, created_at: 1.day.ago, subject: "Zeta recent ticket")
        create(:ticket, user: resident, created_at: 40.days.ago, subject: "Yoga old ticket")

        sign_in resident
        get tickets_tickets_path(created_on_or_after: 5.days.ago.to_date.iso8601)
        expect(response.body).to include("Zeta recent ticket")
        expect(response.body).not_to include("Yoga old ticket")
      end

      it "applies created_on_or_after and created_on_or_before together" do
        create(:ticket, user: resident, created_at: Time.zone.local(2026, 3, 1, 12), subject: "March first ticket")
        create(:ticket, user: resident, created_at: Time.zone.local(2026, 3, 15, 12), subject: "Mid March only")
        create(:ticket, user: resident, created_at: Time.zone.local(2026, 3, 30, 12), subject: "March end ticket")

        sign_in resident
        get tickets_tickets_path(created_on_or_after: "2026-03-10", created_on_or_before: "2026-03-20")
        expect(response.body).to include("Mid March only")
        expect(response.body).not_to include("March first ticket")
        expect(response.body).not_to include("March end ticket")
      end

      it "ignores invalid date params" do
        create(:ticket, subject: "One ticket", user: resident)

        sign_in resident
        get tickets_tickets_path(created_on_or_after: "nope", created_on_or_before: "also-bad")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("One ticket")
      end
    end

    describe "filter by submitter" do
      it "for staff, filters to the selected user" do
        create(:ticket, user: resident, subject: "From A")
        create(:ticket, user: other_resident, subject: "From B")

        sign_in create(:user, :treasurer)
        get tickets_tickets_path(user_id: resident.id)
        expect(response.body).to include("From A")
        expect(response.body).not_to include("From B")
      end

      it "ignores user_id for residents (cannot narrow to another submitter's tickets by param)" do
        create(:ticket, subject: "My ticket", user: resident)
        other = create(:ticket, subject: "Theirs", user: other_resident)

        sign_in resident
        get tickets_tickets_path(user_id: other_resident.id)
        expect(response.body).to include("My ticket")
        expect(response.body).not_to include(other.subject)
      end
    end

    describe "sorting" do
      it "orders by sort param when whitelisted" do
        create(:ticket, subject: "Banana", user: resident)
        create(:ticket, subject: "Apple", user: resident)

        sign_in resident
        get tickets_tickets_path(sort: "subject", dir: "asc")
        expect(response.body.index("Apple")).to be < response.body.index("Banana")
      end

      it "reverses on dir=desc" do
        create(:ticket, subject: "Banana", user: resident)
        create(:ticket, subject: "Apple", user: resident)

        sign_in resident
        get tickets_tickets_path(sort: "subject", dir: "desc")
        expect(response.body.index("Banana")).to be < response.body.index("Apple")
      end

      it "falls back to default sort for unknown sort key" do
        sign_in resident
        get tickets_tickets_path(sort: "evil; DROP TABLE tickets;--")
        expect(response).to have_http_status(:ok)
      end
    end

    describe "pagination" do
      around { |ex| with_pagy_limit(3) { ex.run } }

      it "limits results to one page when there are more than the page size" do
        create_list(:ticket, 5, user: resident)

        sign_in resident
        get tickets_tickets_path
        expect(response.body.scan(/<tr class="[^"]*hover:bg-slate-50[^"]*">/).size).to eq(3)
      end

      it "renders subsequent pages via the page param" do
        create_list(:ticket, 5, user: resident)

        sign_in resident
        get tickets_tickets_path(page: 2)
        expect(response.body.scan(/<tr class="[^"]*hover:bg-slate-50[^"]*">/).size).to eq(2)
      end

      it "preserves filter and sort across pages" do
        create_list(:ticket, 4, user: resident, status: :open)
        create(:ticket, :closed, user: resident, subject: "Closed one")

        sign_in resident
        get tickets_tickets_path(status: "open", sort: "subject", dir: "asc", page: 2)
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Closed one")
      end

      it "keeps date filter in pagination next link" do
        d = 5.days.ago.to_date.iso8601
        with_pagy_limit(1) do
          create_list(:ticket, 2, user: resident, created_at: 1.day.ago, status: :open)

          sign_in resident
          get tickets_tickets_path(created_on_or_after: d, sort: "created_at", dir: "asc")
        end
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Next")
        expect(response.body).to include("created_on_or_after=")
        expect(response.body).to include(d)
      end
    end
  end

  describe "GET /tickets/:id" do
    it "allows the ticket owner to view their ticket" do
      ticket = create(:ticket, subject: "My issue", user: resident)
      sign_in resident
      get tickets_ticket_path(ticket)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My issue")
    end

    { "admin" => :admin, "board member" => :board, "treasurer" => :treasurer }.each do |label, trait|
      it "allows #{label} to view any ticket" do
        ticket = create(:ticket, user: resident)
        sign_in create(:user, trait)
        get tickets_ticket_path(ticket)
        expect(response).to have_http_status(:ok)
      end
    end

    it "denies another resident access" do
      ticket = create(:ticket, user: resident)
      sign_in other_resident
      get tickets_ticket_path(ticket)
      expect(response).to redirect_to(root_path)
    end

    it "shows comments on the ticket" do
      ticket = create(:ticket, user: resident)
      create(:ticket_comment, ticket: ticket, body: "Staff reply here", user: admin)

      sign_in resident
      get tickets_ticket_path(ticket)
      expect(response.body).to include("Staff reply here")
    end
  end

  describe "GET /tickets/new" do
    it "renders the form for authenticated users" do
      sign_in resident
      get new_tickets_ticket_path
      expect(response).to have_http_status(:ok)
    end

    it "requires authentication" do
      get new_tickets_ticket_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /tickets" do
    let(:valid_params) do
      {
        ticket: {
          subject: "Broken fence",
          description: "The fence near the playground is broken.",
          category: "maintenance"
        }
      }
    end

    it "creates a ticket for an authenticated user" do
      sign_in resident
      expect { post tickets_tickets_path, params: valid_params }.to change(Ticket, :count).by(1)

      ticket = Ticket.last
      expect(ticket.user).to eq(resident)
      expect(ticket.subject).to eq("Broken fence")
      expect(ticket.status).to eq("open")
      expect(response).to redirect_to(tickets_ticket_path(ticket))
    end

    it "sends a notification email to admin" do
      create(:user, :admin)
      sign_in resident
      expect { post tickets_tickets_path, params: valid_params }
        .to have_enqueued_mail(TicketMailer, :new_ticket_notification)
    end

    it "re-renders on invalid data" do
      sign_in resident
      post tickets_tickets_path, params: { ticket: { subject: "", description: "", category: "maintenance" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "allows associating a property" do
      property = create(:property)
      create(:membership, user: resident, property: property)

      sign_in resident
      post tickets_tickets_path, params: valid_params.deep_merge(ticket: { property_id: property.id })
      expect(Ticket.last.property).to eq(property)
    end
  end

  describe "PATCH /tickets/:id/update_status" do
    let(:ticket) { create(:ticket, user: resident) }

    { "admin" => :admin, "board member" => :board, "treasurer" => :treasurer }.each do |label, trait|
      it "allows #{label} to update status" do
        sign_in create(:user, trait)
        patch update_status_tickets_ticket_path(ticket), params: { ticket: { status: "in_progress", priority: "high" } }
        expect(response).to redirect_to(tickets_ticket_path(ticket))

        ticket.reload
        expect(ticket.status).to eq("in_progress")
        expect(ticket.priority).to eq("high")
      end
    end

    it "sends a notification when status changes" do
      sign_in admin
      expect do
        patch update_status_tickets_ticket_path(ticket), params: { ticket: { status: "resolved", priority: "normal" } }
      end.to have_enqueued_mail(TicketMailer, :status_change_notification)
    end

    it "sets closed_at when status changes to closed" do
      sign_in admin
      patch update_status_tickets_ticket_path(ticket), params: { ticket: { status: "closed", priority: "normal" } }
      expect(ticket.reload.closed_at).to be_present
    end

    it "clears closed_at when reopened" do
      closed_ticket = create(:ticket, :closed, user: resident)
      sign_in admin
      patch update_status_tickets_ticket_path(closed_ticket), params: { ticket: { status: "open", priority: "normal" } }
      expect(closed_ticket.reload.closed_at).to be_nil
    end

    it "denies status updates for residents" do
      sign_in resident
      patch update_status_tickets_ticket_path(ticket), params: { ticket: { status: "closed", priority: "normal" } }
      expect(response).to redirect_to(root_path)
    end
  end
end
