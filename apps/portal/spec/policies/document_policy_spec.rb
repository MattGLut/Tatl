# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentPolicy do
  subject(:policy) { described_class.new(user, document) }

  let(:document) { create(:document) }

  describe "for an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:destroy) }
  end

  describe "for a board member" do
    let(:user) { create(:user, :board) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:destroy) }
  end

  describe "for a treasurer" do
    let(:user) { create(:user, :treasurer) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:destroy) }
  end

  describe "for a resident" do
    let(:user) { create(:user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:destroy) }

    context "with a published document" do
      let(:document) { create(:document, published_at: Time.current) }

      it { is_expected.to permit_action(:show) }
    end

    context "with a draft document" do
      let(:document) { create(:document, :draft) }

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
    let!(:published_doc) { create(:document) }
    let!(:draft_doc) { create(:document, :draft) }

    context "when user is staff" do
      let(:user) { create(:user, :admin) }
      let(:scope) { described_class::Scope.new(user, Document).resolve }

      it "returns all documents" do
        expect(scope).to include(published_doc, draft_doc)
      end
    end

    context "when user is a resident" do
      let(:user) { create(:user) }
      let(:scope) { described_class::Scope.new(user, Document).resolve }

      it "returns only published documents" do
        expect(scope).to contain_exactly(published_doc)
      end
    end
  end
end
