# frozen_string_literal: true

class Property < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  enum :property_type, {
    single_family: 0,
    townhome: 1,
    condo: 2,
    lot: 3
  }, validate: true

  validates :name, presence: true
  validates :lot_number, uniqueness: true, allow_blank: true

  scope :by_type, ->(type) { where(property_type: type) }
  scope :search, ->(query) { where("name ILIKE :q OR lot_number ILIKE :q OR street_address ILIKE :q", q: "%#{query}%") }
end
