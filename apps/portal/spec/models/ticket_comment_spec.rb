# frozen_string_literal: true

require "rails_helper"

RSpec.describe TicketComment do
  describe "associations" do
    it { is_expected.to belong_to(:ticket) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_one_attached(:file) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
  end

  describe "factory" do
    it "builds a valid ticket comment" do
      expect(build(:ticket_comment)).to be_valid
    end

    it "builds a valid comment with file attachment" do
      comment = build(:ticket_comment, :with_file)
      expect(comment).to be_valid
      expect(comment.file).to be_attached
    end
  end

  describe "scopes" do
    describe ".chronological" do
      it "orders by created_at ascending" do
        ticket = create(:ticket)
        old_comment = create(:ticket_comment, ticket: ticket, created_at: 1.day.ago)
        new_comment = create(:ticket_comment, ticket: ticket, created_at: Time.current)
        expect(described_class.chronological).to eq([old_comment, new_comment])
      end
    end
  end
end
