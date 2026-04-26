# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounting::ReportPolicy do
  subject(:policy) { described_class.new(user, :report) }

  describe "for an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_action(:summary) }
    it { is_expected.to permit_action(:dues_aging) }
    it { is_expected.to permit_action(:reserve_balance) }
  end

  describe "for a treasurer" do
    let(:user) { create(:user, :treasurer) }

    it { is_expected.to permit_action(:summary) }
    it { is_expected.to permit_action(:dues_aging) }
    it { is_expected.to permit_action(:reserve_balance) }
  end

  describe "for a board member" do
    let(:user) { create(:user, :board) }

    it { is_expected.to permit_action(:summary) }
    it { is_expected.to permit_action(:dues_aging) }
    it { is_expected.to permit_action(:reserve_balance) }
  end

  describe "for a resident" do
    let(:user) { create(:user) }

    it { is_expected.not_to permit_action(:summary) }
    it { is_expected.to permit_action(:dues_aging) }
    it { is_expected.not_to permit_action(:reserve_balance) }
  end
end
