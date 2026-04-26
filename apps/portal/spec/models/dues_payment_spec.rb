# frozen_string_literal: true

require "rails_helper"

RSpec.describe DuesPayment do
  describe "associations" do
    it { is_expected.to belong_to(:dues_assessment) }
    it { is_expected.to belong_to(:ledger_transaction).class_name("Transaction").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:paid_on) }

    it "requires amount_cents greater than 0" do
      payment = build(:dues_payment, amount_cents: 0)
      expect(payment).not_to be_valid
    end
  end

  describe "monetize" do
    it "monetizes amount_cents" do
      payment = build(:dues_payment, amount_cents: 5_000)
      expect(payment.amount).to eq(Money.new(5_000, "USD"))
    end
  end

  describe "factory" do
    it "creates a valid dues payment" do
      expect(build(:dues_payment)).to be_valid
    end
  end

  describe "callbacks" do
    it "recalculates assessment status after create" do
      assessment = create(:dues_assessment, amount_cents: 10_000)
      create(:dues_payment, dues_assessment: assessment, amount_cents: 10_000)

      expect(assessment.reload.status).to eq("paid")
    end

    it "recalculates assessment status after destroy" do
      assessment = create(:dues_assessment, amount_cents: 10_000)
      payment = create(:dues_payment, dues_assessment: assessment, amount_cents: 10_000)
      expect(assessment.reload.status).to eq("paid")

      payment.destroy!
      expect(assessment.reload.status).to eq("overdue").or eq("open")
    end
  end
end
