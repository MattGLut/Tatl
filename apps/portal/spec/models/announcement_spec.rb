# frozen_string_literal: true

require "rails_helper"

RSpec.describe Announcement do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:title).is_at_most(120) }
    it { is_expected.to validate_length_of(:body).is_at_most(1_000) }
  end

  describe "factory" do
    it "builds a valid announcement" do
      expect(build(:announcement)).to be_valid
    end
  end

  describe "scopes" do
    describe ".active_now" do
      it "returns active announcements only" do
        active = create(:announcement)
        create(:announcement, :inactive)

        expect(described_class.active_now).to contain_exactly(active)
      end
    end

    describe ".currently_pinned" do
      it "returns unexpired and unpinned announcements" do
        unexpired = create(:announcement, pinned_until: 2.hours.from_now)
        unpinned = create(:announcement, :unpinned)
        create(:announcement, :expired)

        expect(described_class.currently_pinned).to contain_exactly(unexpired, unpinned)
      end
    end

    describe ".visible" do
      it "includes only active and currently pinned announcements" do
        visible = create(:announcement, title: "Visible")
        create(:announcement, :inactive, title: "Inactive")
        create(:announcement, :expired, title: "Expired")

        expect(described_class.visible).to contain_exactly(visible)
      end

      it "orders pinned announcements first, then newest" do
        old_unpinned = create(:announcement, :unpinned, created_at: 2.days.ago, title: "Old")
        recent_unpinned = create(:announcement, :unpinned, created_at: 1.day.ago, title: "Recent")
        pinned = create(:announcement, pinned_until: 1.day.from_now, created_at: 3.days.ago, title: "Pinned")

        expect(described_class.visible).to eq([pinned, recent_unpinned, old_unpinned])
      end
    end
  end
end
