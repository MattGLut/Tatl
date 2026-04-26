# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetLine do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    subject { build(:budget_line) }

    it { is_expected.to validate_presence_of(:fiscal_year) }

    it "validates uniqueness of account_id scoped to fiscal_year" do
      existing = create(:budget_line)
      dupe = build(:budget_line, account: existing.account, fiscal_year: existing.fiscal_year)
      expect(dupe).not_to be_valid
    end

    it "rejects fiscal_year <= 2000" do
      budget_line = build(:budget_line, fiscal_year: 2000)
      expect(budget_line).not_to be_valid
    end
  end

  describe "monetize" do
    it "monetizes amount_cents" do
      bl = build(:budget_line, amount_cents: 50_000)
      expect(bl.amount).to eq(Money.new(50_000, "USD"))
    end
  end

  describe "factory" do
    it "builds a valid budget line" do
      expect(build(:budget_line)).to be_valid
    end
  end

  describe "scopes" do
    describe ".for_year" do
      it "filters by fiscal year" do
        bl_2026 = create(:budget_line, fiscal_year: 2026)
        create(:budget_line, fiscal_year: 2025)

        expect(described_class.for_year(2026)).to eq([bl_2026])
      end
    end
  end
end
