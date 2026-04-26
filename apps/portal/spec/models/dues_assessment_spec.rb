# frozen_string_literal: true

require "rails_helper"

RSpec.describe DuesAssessment do
  describe "associations" do
    it { is_expected.to belong_to(:property) }
    it { is_expected.to belong_to(:ledger_transaction).class_name("Transaction").optional }
    it { is_expected.to have_many(:dues_payments).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:period_start) }
    it { is_expected.to validate_presence_of(:period_end) }
    it { is_expected.to validate_presence_of(:due_date) }

    it "requires amount_cents greater than 0" do
      assessment = build(:dues_assessment, amount_cents: 0)
      expect(assessment).not_to be_valid
    end

    it "requires period_end after period_start" do
      assessment = build(:dues_assessment, period_start: Date.current, period_end: 1.day.ago.to_date)
      expect(assessment).not_to be_valid
      expect(assessment.errors[:period_end]).to be_present
    end
  end

  describe "enum" do
    it "defines status values" do
      expect(described_class.statuses.keys).to match_array(%w[open partial paid overdue])
    end
  end

  describe "monetize" do
    it "monetizes amount_cents" do
      assessment = build(:dues_assessment, amount_cents: 25_000)
      expect(assessment.amount).to eq(Money.new(25_000, "USD"))
    end
  end

  describe "factory" do
    it "builds a valid dues assessment" do
      expect(build(:dues_assessment)).to be_valid
    end

    %i[overdue partial paid].each do |trait|
      it "builds a valid #{trait} assessment" do
        expect(build(:dues_assessment, trait)).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".open_or_partial" do
      it "returns open and partial assessments" do
        open_a = create(:dues_assessment, status: :open)
        partial_a = create(:dues_assessment, status: :partial)
        create(:dues_assessment, status: :paid)

        expect(described_class.open_or_partial).to contain_exactly(open_a, partial_a)
      end
    end

    describe ".overdue" do
      it "returns overdue assessments" do
        overdue_a = create(:dues_assessment, :overdue)
        create(:dues_assessment)

        expect(described_class.overdue).to eq([overdue_a])
      end
    end

    describe ".for_property" do
      it "filters by property" do
        assessment = create(:dues_assessment)
        create(:dues_assessment)

        expect(described_class.for_property(assessment.property_id)).to eq([assessment])
      end
    end
  end

  describe "#recalculate_status!" do
    let(:assessment) { create(:dues_assessment, amount_cents: 10_000) }

    it "sets paid when payments cover full amount" do
      create(:dues_payment, dues_assessment: assessment, amount_cents: 10_000)
      assessment.recalculate_status!
      expect(assessment.reload.status).to eq("paid")
    end

    it "sets partial when payments cover some amount" do
      create(:dues_payment, dues_assessment: assessment, amount_cents: 5_000)
      assessment.recalculate_status!
      expect(assessment.reload.status).to eq("partial")
    end

    it "sets overdue when past due with no payments" do
      assessment.update!(due_date: 10.days.ago.to_date)
      assessment.recalculate_status!
      expect(assessment.reload.status).to eq("overdue")
    end

    it "sets open when not yet due with no payments" do
      assessment.update!(due_date: 10.days.from_now.to_date)
      assessment.recalculate_status!
      expect(assessment.reload.status).to eq("open")
    end
  end
end
