# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { Object.new }

  describe "#admin?" do
    context "when user is admin" do
      let(:user) { build(:user, :admin) }

      it { is_expected.to be_admin }
    end

    %i[resident board treasurer].each do |role|
      context "when user is #{role}" do
        let(:user) { build(:user, role) }

        it { is_expected.not_to be_admin }
      end
    end

    context "when user is nil" do
      let(:user) { nil }

      it { is_expected.not_to be_admin }
    end
  end

  describe "#staff?" do
    %i[admin board treasurer].each do |role|
      context "when user is #{role}" do
        let(:user) { build(:user, role) }

        it { is_expected.to be_staff }
      end
    end

    context "when user is resident" do
      let(:user) { build(:user) }

      it { is_expected.not_to be_staff }
    end

    context "when user is nil" do
      let(:user) { nil }

      it { is_expected.not_to be_staff }
    end
  end

  describe "default permissions" do
    let(:user) { build(:user, :admin) }

    %i[index? show? create? new? update? edit? destroy?].each do |perm|
      it "denies #{perm} by default" do
        expect(policy.public_send(perm)).to be false
      end
    end
  end
end
