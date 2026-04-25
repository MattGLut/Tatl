# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "associations & validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    it "defines the role enum" do
      expect(described_class.roles.keys).to match_array(%w[resident board treasurer admin])
    end

    it "defaults to resident" do
      expect(described_class.new.role).to eq("resident")
    end
  end

  describe "factory" do
    it "builds a valid user" do
      expect(build(:user)).to be_valid
    end

    %i[board treasurer admin].each do |role|
      it "builds a valid #{role}" do
        user = build(:user, role)
        expect(user).to be_valid
        expect(user.public_send("#{role}?")).to be true
      end
    end
  end

  describe "#display_name" do
    it "returns the full name when present" do
      user = build(:user, first_name: "Ada", last_name: "Lovelace")
      expect(user.display_name).to eq("Ada Lovelace")
    end

    it "falls back to email when names are blank" do
      user = build(:user, first_name: "", last_name: "")
      expect(user.display_name).to eq(user.email)
    end
  end

  describe "Devise modules" do
    it "includes the configured modules" do
      expect(described_class.devise_modules).to include(
        :database_authenticatable,
        :registerable,
        :recoverable,
        :rememberable,
        :validatable,
        :confirmable,
        :lockable,
        :trackable
      )
    end
  end
end
