# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounting::DuesAssessmentPolicy do
  subject(:policy) { described_class.new(user, assessment) }

  let(:property) { create(:property) }
  let(:assessment) { create(:dues_assessment, property: property) }

  describe "for an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  describe "for a treasurer" do
    let(:user) { create(:user, :treasurer) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
  end

  describe "for a board member" do
    let(:user) { create(:user, :board) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
  end

  describe "for a resident" do
    let(:user) { create(:user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }

    context "with an active membership on the property" do
      before { create(:membership, user: user, property: property) }

      it { is_expected.to permit_action(:show) }
    end

    context "without membership on the property" do
      it { is_expected.not_to permit_action(:show) }
    end
  end

  describe "Scope" do
    let!(:owned_property) { create(:property) }
    let!(:other_property) { create(:property) }
    let!(:owned_assessment) { create(:dues_assessment, property: owned_property) }
    let!(:other_assessment) { create(:dues_assessment, property: other_property) }

    context "when user is staff" do
      let(:user) { create(:user, :admin) }
      let(:scope) { described_class::Scope.new(user, DuesAssessment).resolve }

      it "returns all assessments" do
        expect(scope).to include(owned_assessment, other_assessment)
      end
    end

    context "when user is a resident" do
      let(:user) { create(:user) }
      let(:scope) { described_class::Scope.new(user, DuesAssessment).resolve }

      before { create(:membership, user: user, property: owned_property) }

      it "returns only assessments for their properties" do
        expect(scope).to contain_exactly(owned_assessment)
      end
    end
  end
end
