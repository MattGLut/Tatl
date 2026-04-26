# frozen_string_literal: true

require "rails_helper"

RSpec.describe TicketPolicy do
  subject(:policy) { described_class.new(user, ticket) }

  let(:owner) { create(:user) }
  let(:other_resident) { create(:user) }
  let(:ticket) { create(:ticket, user: owner) }

  shared_examples "staff ticket permissions" do
    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update_status) }
  end

  describe "for an admin" do
    let(:user) { create(:user, :admin) }

    it_behaves_like "staff ticket permissions"
  end

  describe "for a board member" do
    let(:user) { create(:user, :board) }

    it_behaves_like "staff ticket permissions"
  end

  describe "for a treasurer" do
    let(:user) { create(:user, :treasurer) }

    it_behaves_like "staff ticket permissions"
  end

  describe "for the ticket owner (resident)" do
    let(:user) { owner }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.not_to permit_action(:update_status) }
  end

  describe "for another resident" do
    let(:user) { other_resident }

    it { is_expected.to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.not_to permit_action(:update_status) }
  end

  describe "for a guest (nil user)" do
    let(:user) { nil }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update_status) }
  end

  describe "Scope" do
    let!(:owners_ticket) { create(:ticket, user: owner) }
    let!(:others_ticket) { create(:ticket, user: other_resident) }

    context "when user is admin" do
      let(:user) { create(:user, :admin) }
      let(:scope) { described_class::Scope.new(user, Ticket).resolve }

      it "returns all tickets" do
        expect(scope).to contain_exactly(owners_ticket, others_ticket)
      end
    end

    context "when user is board" do
      let(:user) { create(:user, :board) }
      let(:scope) { described_class::Scope.new(user, Ticket).resolve }

      it "returns all tickets" do
        expect(scope).to contain_exactly(owners_ticket, others_ticket)
      end
    end

    context "when user is treasurer" do
      let(:user) { create(:user, :treasurer) }
      let(:scope) { described_class::Scope.new(user, Ticket).resolve }

      it "returns all tickets" do
        expect(scope).to contain_exactly(owners_ticket, others_ticket)
      end
    end

    context "when user is a resident" do
      let(:user) { owner }
      let(:scope) { described_class::Scope.new(user, Ticket).resolve }

      it "returns only that user's tickets" do
        expect(scope).to contain_exactly(owners_ticket)
      end
    end
  end
end
