# frozen_string_literal: true

require "rails_helper"

RSpec.describe TicketMailer do
  let!(:admin) { create(:user, :admin) }
  let(:resident) { create(:user) }
  let(:ticket) { create(:ticket, user: resident, subject: "Broken gate") }

  describe "#new_ticket_notification" do
    it "sends to admin users" do
      mail = described_class.new_ticket_notification(ticket)
      expect(mail.to).to include(admin.email)
      expect(mail.subject).to eq("New ticket: Broken gate")
    end

    it "includes ticket details in the body" do
      mail = described_class.new_ticket_notification(ticket)
      expect(mail.body.to_s).to include("Broken gate")
      expect(mail.body.to_s).to include(resident.display_name)
    end

    it "returns nil when no admin exists" do
      admin.destroy!
      mail = described_class.new_ticket_notification(ticket)
      expect(mail.to).to be_nil
    end
  end

  describe "#status_change_notification" do
    it "sends to the ticket owner" do
      mail = described_class.status_change_notification(ticket)
      expect(mail.to).to include(resident.email)
      expect(mail.subject).to eq("Ticket updated: Broken gate")
    end

    it "includes the current status" do
      ticket.update!(status: :resolved)
      mail = described_class.status_change_notification(ticket)
      expect(mail.body.encoded).to include("Resolved")
    end
  end

  describe "#new_comment_notification" do
    context "when a staff member comments" do
      let(:comment) { create(:ticket_comment, ticket: ticket, user: admin, body: "We fixed it") }

      it "sends to the ticket owner" do
        mail = described_class.new_comment_notification(comment)
        expect(mail.to).to include(resident.email)
        expect(mail.subject).to include("Broken gate")
      end

      it "includes the comment body" do
        mail = described_class.new_comment_notification(comment)
        expect(mail.body.encoded).to include("We fixed it")
      end
    end

    context "when the ticket owner comments" do
      let(:comment) { create(:ticket_comment, ticket: ticket, user: resident, body: "Any update?") }

      it "sends to admin users" do
        mail = described_class.new_comment_notification(comment)
        expect(mail.to).to include(admin.email)
      end
    end
  end
end
