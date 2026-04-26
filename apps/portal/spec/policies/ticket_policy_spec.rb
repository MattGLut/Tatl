# frozen_string_literal: true

require "rails_helper"

RSpec.describe TicketPolicy do
  subject(:policy) { described_class.new(user, ticket) }

  let(:ticket_owner) { create(:user) }
  let(:ticket) { create(:ticket, user: ticket_owner) }

  describe "for an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update_status) }
  end

  describe "for a board member" do
    let(:user) { create(:user, :board) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update_status) }
  end

  describe "for a treasurer" do
    let(:user) { create(:user, :treasurer) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update_status) }
  end

  describe "for the ticket owner (resident)" do
    let(:user) { ticket_owner }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.not_to permit_action(:update_status) }
  end

  describe "for another resident" do
    let(:user) { create(:user) }

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
    let!(:own_ticket) { create(:ticket, user: resident) }
    let!(:other_ticket) { create(:ticket) }
    let(:resident) { create(:user) }

    context "when user is staff" do
      let(:user) { create(:user, :admin) }
      let(:scope) { described_class::Scope.new(user, Ticket).resolve }

      it "returns all tickets" do
        expect(scope).to include(own_ticket, other_ticket)
      end
    end

    context "when user is a resident" do
      let(:user) { resident }
      let(:scope) { described_class::Scope.new(user, Ticket).resolve }

      it "returns only the user's own tickets" do
        expect(scope).to contain_exactly(own_ticket)
      end
    end
  end
end
