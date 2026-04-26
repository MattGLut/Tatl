# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounting::TransactionPolicy do
  subject(:policy) { described_class.new(user, txn) }

  let(:txn) { create(:transaction) }

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
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
  end

  describe "for a resident" do
    let(:user) { create(:user) }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
  end
end
