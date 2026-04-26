# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account do
  describe "associations" do
    it { is_expected.to have_many(:transactions).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:budget_lines).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:account) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "enum" do
    it "defines account_type" do
      expect(described_class.account_types.keys).to match_array(%w[operating reserve income expense])
    end
  end

  describe "factory" do
    it "builds a valid account" do
      expect(build(:account)).to be_valid
    end

    %i[reserve income expense inactive].each do |trait|
      it "builds a valid #{trait} account" do
        expect(build(:account, trait)).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active accounts" do
        active = create(:account)
        create(:account, :inactive)

        expect(described_class.active).to eq([active])
      end
    end

    describe ".by_type" do
      it "filters by account type" do
        reserve = create(:account, :reserve)
        create(:account, :income)

        expect(described_class.by_type(:reserve)).to eq([reserve])
      end
    end
  end
end
