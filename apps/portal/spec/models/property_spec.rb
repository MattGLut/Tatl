# frozen_string_literal: true

require "rails_helper"

RSpec.describe Property do
  describe "associations" do
    it { is_expected.to have_many(:memberships).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:memberships) }
  end

  describe "validations" do
    subject { build(:property) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:lot_number) }
  end

  describe "enum" do
    it "defines property_type" do
      expect(described_class.property_types.keys).to match_array(%w[single_family townhome condo lot])
    end
  end

  describe "factory" do
    it "builds a valid property" do
      expect(build(:property)).to be_valid
    end

    %i[townhome condo lot].each do |trait|
      it "builds a valid #{trait}" do
        property = build(:property, trait)
        expect(property).to be_valid
        expect(property.property_type).to eq(trait.to_s)
      end
    end
  end

  describe "scopes" do
    describe ".by_type" do
      it "filters by property type" do
        condo = create(:property, :condo)
        create(:property, :townhome)

        expect(described_class.by_type(:condo)).to eq([condo])
      end
    end

    describe ".search" do
      it "searches by name, lot number, or address" do
        prop = create(:property, name: "Sunset Villa", lot_number: "SV-001", street_address: "42 Oak Ave")

        expect(described_class.search("Sunset")).to include(prop)
        expect(described_class.search("SV-001")).to include(prop)
        expect(described_class.search("Oak")).to include(prop)
        expect(described_class.search("Nonexistent")).to be_empty
      end
    end
  end

  describe "lot_number uniqueness" do
    it "allows blank lot numbers on multiple records" do
      create(:property, lot_number: nil)
      expect(build(:property, lot_number: nil)).to be_valid
    end

    it "rejects duplicate non-blank lot numbers" do
      create(:property, lot_number: "LOT-1")
      expect(build(:property, lot_number: "LOT-1")).not_to be_valid
    end
  end
end
