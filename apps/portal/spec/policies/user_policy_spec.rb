# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy do
  subject(:policy) { described_class.new(user, record) }

  describe "#destroy?" do
    context "when targeting another user" do
      let(:record) { create(:user) }

      %i[admin board treasurer].each do |role|
        context "when the user is a #{role}" do
          let(:user) { create(:user, role) }

          it { is_expected.to forbid_action(:destroy) }
        end
      end

      context "when the user is a resident" do
        let(:user) { create(:user) }

        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when the user is destroying themself" do
      let(:user) { create(:user, :admin) }
      let(:record) { user }

      it { is_expected.to forbid_action(:destroy) }
    end

    context "without an authenticated user" do
      let(:user) { nil }
      let(:record) { create(:user) }

      it { is_expected.to forbid_action(:destroy) }
    end
  end
end
