# frozen_string_literal: true

require "rails_helper"

RSpec.describe PropertyPolicy do
  subject(:policy) { described_class.new(user, property) }

  let(:property) { create(:property) }

  describe "for an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  describe "for a board member" do
    let(:user) { create(:user, :board) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
  end

  describe "for a treasurer" do
    let(:user) { create(:user, :treasurer) }

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

    context "when the resident has an active membership" do
      before { create(:membership, user: user, property: property) }

      it { is_expected.to permit_action(:show) }
    end

    context "when the resident has no membership" do
      it { is_expected.not_to permit_action(:show) }
    end
  end

  describe "for a guest (nil user)" do
    let(:user) { nil }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
  end

  describe "Scope" do
    let!(:property_with_member) { create(:property) }
    let!(:property_without_member) { create(:property) }

    context "when user is staff" do
      let(:user) { create(:user, :admin) }
      let(:scope) { described_class::Scope.new(user, Property).resolve }

      it "returns all properties" do
        expect(scope).to include(property_with_member, property_without_member)
      end
    end

    context "when user is a resident" do
      let(:user) { create(:user) }
      let(:scope) { described_class::Scope.new(user, Property).resolve }

      before { create(:membership, user: user, property: property_with_member) }

      it "returns only properties with active membership" do
        expect(scope).to contain_exactly(property_with_member)
      end
    end
  end
end
