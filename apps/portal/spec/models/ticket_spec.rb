# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ticket do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:property).optional }
    it { is_expected.to have_many(:ticket_comments).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe "enums" do
    it "defines category" do
      expect(described_class.categories.keys).to match_array(
        %w[maintenance landscaping noise_complaint parking common_area dues_question suggestion other]
      )
    end

    it "defines priority" do
      expect(described_class.priorities.keys).to match_array(%w[low normal high urgent])
    end

    it "defines status" do
      expect(described_class.statuses.keys).to match_array(%w[open in_progress resolved closed])
    end
  end

  describe "defaults" do
    subject(:ticket) { build(:ticket) }

    it "defaults priority to normal" do
      expect(ticket.priority).to eq("normal")
    end

    it "defaults status to open" do
      expect(ticket.status).to eq("open")
    end
  end

  describe "factory" do
    it "builds a valid ticket" do
      expect(build(:ticket)).to be_valid
    end

    it "builds a valid ticket with property" do
      expect(build(:ticket, :with_property)).to be_valid
    end

    %i[landscaping noise_complaint parking suggestion dues_question].each do |trait|
      it "builds a valid #{trait} category ticket" do
        ticket = build(:ticket, trait)
        expect(ticket).to be_valid
        expect(ticket.category).to eq(trait.to_s)
      end
    end

    %i[in_progress resolved closed].each do |trait|
      it "builds a valid #{trait} status ticket" do
        ticket = build(:ticket, trait)
        expect(ticket).to be_valid
        expect(ticket.status).to eq(trait.to_s)
      end
    end
  end

  describe "scopes" do
    let!(:open_ticket) { create(:ticket) }
    let!(:closed_ticket) { create(:ticket, :closed) } # rubocop:disable RSpec/LetSetup
    let!(:resolved_ticket) { create(:ticket, :resolved) }

    describe ".by_status" do
      it "filters by status" do
        expect(described_class.by_status(:open)).to contain_exactly(open_ticket)
      end
    end

    describe ".by_category" do
      it "filters by category" do
        landscaping = create(:ticket, :landscaping)
        expect(described_class.by_category(:landscaping)).to contain_exactly(landscaping)
      end
    end

    describe ".by_priority" do
      it "filters by priority" do
        urgent = create(:ticket, :urgent)
        expect(described_class.by_priority(:urgent)).to contain_exactly(urgent)
      end
    end

    describe ".active" do
      it "returns open and in_progress tickets" do
        in_progress = create(:ticket, :in_progress)
        expect(described_class.active).to contain_exactly(open_ticket, in_progress)
      end
    end

    describe ".recent" do
      it "orders by created_at descending" do
        expect(described_class.recent.first).to eq(resolved_ticket)
      end
    end
  end

  describe "#close!" do
    it "sets status to closed and records closed_at" do
      ticket = create(:ticket)
      ticket.close!
      expect(ticket.status).to eq("closed")
      expect(ticket.closed_at).to be_present
    end
  end

  describe "#reopen!" do
    it "sets status to open and clears closed_at" do
      ticket = create(:ticket, :closed)
      ticket.reopen!
      expect(ticket.status).to eq("open")
      expect(ticket.closed_at).to be_nil
    end
  end
end
