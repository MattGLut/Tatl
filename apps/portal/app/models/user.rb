# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable,
         :lockable,
         :trackable

  enum :role, {
    resident: 0,
    board: 1,
    treasurer: 2,
    admin: 3
  }, default: :resident, validate: true

  validates :first_name, :last_name, presence: true

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  def display_name
    full_name.presence || email
  end
end
