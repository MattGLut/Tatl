# frozen_string_literal: true

require "rails_helper"

RSpec.describe Document do
  describe "associations" do
    it { is_expected.to belong_to(:uploaded_by).class_name("User") }
    it { is_expected.to have_one_attached(:file) }
  end

  describe "validations" do
    subject { build(:document) }

    it { is_expected.to validate_presence_of(:title) }
  end

  describe "enums" do
    it "defines category" do
      expect(described_class.categories.keys).to match_array(%w[policy bylaws minutes financial_report form other])
    end

    it "defines rag_sync_status" do
      expect(described_class.rag_sync_statuses.keys).to match_array(%w[pending indexed failed])
    end
  end

  describe "factory" do
    it "builds a valid document" do
      expect(build(:document)).to be_valid
    end

    it "builds a valid draft" do
      doc = build(:document, :draft)
      expect(doc).to be_valid
      expect(doc.published_at).to be_nil
    end

    %i[bylaws minutes financial_report form].each do |trait|
      it "builds a valid #{trait} document" do
        doc = build(:document, trait)
        expect(doc).to be_valid
        expect(doc.category).to eq(trait.to_s)
      end
    end
  end

  describe "#published?" do
    it "returns true when published_at is set" do
      expect(build(:document, published_at: Time.current)).to be_published
    end

    it "returns false when published_at is nil" do
      expect(build(:document, :draft)).not_to be_published
    end
  end

  describe "scopes" do
    let!(:published_doc) { create(:document) }
    let!(:draft_doc) { create(:document, :draft) }

    describe ".published" do
      it "returns only published documents" do
        expect(described_class.published).to contain_exactly(published_doc)
      end
    end

    describe ".drafts" do
      it "returns only draft documents" do
        expect(described_class.drafts).to contain_exactly(draft_doc)
      end
    end

    describe ".by_category" do
      it "filters by category" do
        bylaws_doc = create(:document, :bylaws)
        expect(described_class.by_category(:bylaws)).to contain_exactly(bylaws_doc)
      end
    end

    describe ".recent" do
      it "orders by created_at descending" do
        expect(described_class.recent.first).to eq(draft_doc)
      end
    end
  end

  describe "file validation on create" do
    it "is invalid without a file on create" do
      doc = described_class.new(title: "Test", category: :policy, uploaded_by: create(:user))
      expect(doc).not_to be_valid
      expect(doc.errors[:file]).to include("can't be blank")
    end
  end
end
