# frozen_string_literal: true

require "rails_helper"

RSpec.describe TicketCommentPolicy do
  subject(:policy) { described_class.new(user, comment) }

  let(:ticket_owner) { create(:user) }
  let(:ticket) { create(:ticket, user: ticket_owner) }
  let(:comment) { build(:ticket_comment, ticket: ticket) }

  describe "for an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_action(:create) }
  end

  describe "for a board member" do
    let(:user) { create(:user, :board) }

    it { is_expected.to permit_action(:create) }
  end

  describe "for a treasurer" do
    let(:user) { create(:user, :treasurer) }

    it { is_expected.to permit_action(:create) }
  end

  describe "for the ticket owner" do
    let(:user) { ticket_owner }

    it { is_expected.to permit_action(:create) }
  end

  describe "for another resident" do
    let(:user) { create(:user) }

    it { is_expected.not_to permit_action(:create) }
  end

  describe "for a guest (nil user)" do
    let(:user) { nil }

    it { is_expected.not_to permit_action(:create) }
  end
end
