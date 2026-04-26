# frozen_string_literal: true

require "rails_helper"

RSpec.describe Membership do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:property) }
  end

  describe "validations" do
    subject { build(:membership) }

    it { is_expected.to validate_presence_of(:started_on) }
  end

  describe "enum" do
    it "defines role" do
      expect(described_class.roles.keys).to match_array(%w[owner resident tenant])
    end
  end

  describe "factory" do
    it "builds a valid membership" do
      expect(build(:membership)).to be_valid
    end

    %i[resident tenant ended].each do |trait|
      it "builds a valid #{trait} membership" do
        expect(build(:membership, trait)).to be_valid
      end
    end
  end

  describe "#ended_on_after_started_on" do
    it "is invalid when ended_on is before started_on" do
      membership = build(:membership, started_on: Date.current, ended_on: 1.day.ago.to_date)
      expect(membership).not_to be_valid
      expect(membership.errors[:ended_on]).to include("must be after started on")
    end

    it "is invalid when ended_on equals started_on" do
      membership = build(:membership, started_on: Date.current, ended_on: Date.current)
      expect(membership).not_to be_valid
    end

    it "is valid when ended_on is after started_on" do
      membership = build(:membership, started_on: 1.month.ago.to_date, ended_on: Date.current)
      expect(membership).to be_valid
    end
  end

  describe "scopes" do
    let!(:active_membership) { create(:membership) }
    let!(:ended_membership) { create(:membership, :ended) }

    describe ".active" do
      it "returns only memberships without an end date" do
        expect(described_class.active).to contain_exactly(active_membership)
      end
    end

    describe ".ended" do
      it "returns only memberships with an end date" do
        expect(described_class.ended).to contain_exactly(ended_membership)
      end
    end

    describe ".for_user" do
      it "filters by user_id" do
        expect(described_class.for_user(active_membership.user_id)).to contain_exactly(active_membership)
      end
    end

    describe ".for_property" do
      it "filters by property_id" do
        expect(described_class.for_property(active_membership.property_id)).to contain_exactly(active_membership)
      end
    end
  end

  describe "uniqueness constraint" do
    it "prevents duplicate active memberships for the same user and property" do
      membership = create(:membership)
      duplicate = build(:membership, user: membership.user, property: membership.property)
      expect(duplicate).not_to be_valid
    end
  end
end
