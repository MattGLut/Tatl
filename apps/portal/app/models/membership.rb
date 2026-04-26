# frozen_string_literal: true

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :property

  enum :role, {
    owner: 0,
    resident: 1,
    tenant: 2
  }, validate: true

  validates :started_on, presence: true
  validates :user_id, uniqueness: {
    scope: %i[property_id ended_on],
    message: "already has an active membership for this property"
  }
  validate :ended_on_after_started_on, if: -> { ended_on.present? }

  scope :active, -> { where(ended_on: nil) }
  scope :ended, -> { where.not(ended_on: nil) }
  scope :for_property, ->(property_id) { where(property_id: property_id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }

  private

  def ended_on_after_started_on
    return if ended_on > started_on

    errors.add(:ended_on, "must be after started on")
  end
end
