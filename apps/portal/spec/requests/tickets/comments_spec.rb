# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tickets::Comments" do
  let(:admin) { create(:user, :admin) }
  let(:resident) { create(:user) }
  let(:other_resident) { create(:user) }
  let(:ticket) { create(:ticket, user: resident) }

  describe "POST /tickets/:ticket_id/comments" do
    it "allows the ticket owner to add a comment" do
      sign_in resident
      expect do
        post tickets_ticket_comments_path(ticket), params: { ticket_comment: { body: "Resident follow-up" } }
      end.to change(TicketComment, :count).by(1)

      comment = TicketComment.last
      expect(comment.user).to eq(resident)
      expect(comment.body).to eq("Resident follow-up")
      expect(response).to redirect_to(tickets_ticket_path(ticket))
    end

    it "allows staff to add a comment" do
      sign_in admin
      expect do
        post tickets_ticket_comments_path(ticket), params: { ticket_comment: { body: "Admin response" } }
      end.to change(TicketComment, :count).by(1)
      expect(response).to redirect_to(tickets_ticket_path(ticket))
    end

    it "sends a notification email" do
      sign_in admin
      expect do
        post tickets_ticket_comments_path(ticket), params: { ticket_comment: { body: "We're on it" } }
      end.to have_enqueued_mail(TicketMailer, :new_comment_notification)
    end

    it "denies another resident from commenting" do
      sign_in other_resident
      post tickets_ticket_comments_path(ticket), params: { ticket_comment: { body: "Snooping" } }
      expect(response).to redirect_to(root_path)
    end

    it "re-renders on invalid data" do
      sign_in resident
      post tickets_ticket_comments_path(ticket), params: { ticket_comment: { body: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "supports file attachments" do
      sign_in resident
      file = Rack::Test::UploadedFile.new(StringIO.new("photo"), "image/png", true, original_filename: "photo.png")
      post tickets_ticket_comments_path(ticket), params: { ticket_comment: { body: "See attached", file: file } }

      comment = TicketComment.last
      expect(comment.file).to be_attached
    end
  end
end
