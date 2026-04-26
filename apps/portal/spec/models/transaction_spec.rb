# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transaction do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:recorded_by).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:transacted_on) }

    it "rejects zero amount" do
      txn = build(:transaction, amount_cents: 0)
      expect(txn).not_to be_valid
      expect(txn.errors[:amount_cents]).to be_present
    end
  end

  describe "monetize" do
    it "monetizes amount_cents" do
      txn = build(:transaction, amount_cents: 10_000)
      expect(txn.amount).to eq(Money.new(10_000, "USD"))
    end
  end

  describe "factory" do
    it "builds a valid transaction" do
      expect(build(:transaction)).to be_valid
    end

    it "builds a valid expense" do
      txn = build(:transaction, :expense)
      expect(txn).to be_valid
      expect(txn.amount_cents).to be_negative
    end
  end

  describe "scopes" do
    let!(:recent_txn) { create(:transaction, transacted_on: Date.current) }
    let!(:old_txn) { create(:transaction, transacted_on: 60.days.ago.to_date) }

    describe ".recent" do
      it "orders by transacted_on desc" do
        expect(described_class.recent.first).to eq(recent_txn)
      end
    end

    describe ".for_account" do
      it "filters by account" do
        expect(described_class.for_account(recent_txn.account_id)).to include(recent_txn)
        expect(described_class.for_account(recent_txn.account_id)).not_to include(old_txn)
      end
    end

    describe ".in_period" do
      it "filters transactions within date range" do
        results = described_class.in_period(7.days.ago.to_date, Date.current)

        expect(results).to include(recent_txn)
        expect(results).not_to include(old_txn)
      end
    end
  end
end
