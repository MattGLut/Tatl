# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnnouncementPolicy do
  subject(:policy) { described_class.new(user, announcement) }

  let(:announcement) { create(:announcement) }

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

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
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

  describe "for a guest (nil user)" do
    let(:user) { nil }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
  end

  describe "Scope" do
    let!(:first_announcement) { create(:announcement, title: "First", created_at: 2.days.ago) }
    let!(:second_announcement) { create(:announcement, title: "Second", created_at: 1.day.ago) }

    context "when user is admin" do
      let(:user) { create(:user, :admin) }
      let(:scope) { described_class::Scope.new(user, Announcement).resolve }

      it "returns announcements" do
        expect(scope).to eq([second_announcement, first_announcement])
      end
    end

    context "when user is not admin" do
      let(:user) { create(:user) }
      let(:scope) { described_class::Scope.new(user, Announcement).resolve }

      it "returns no records" do
        expect(scope).to be_empty
      end
    end
  end
end
