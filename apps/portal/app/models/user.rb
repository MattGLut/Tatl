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

  has_many :memberships, dependent: :destroy
  has_many :properties, through: :memberships
  has_many :uploaded_documents, class_name: "Document",
                                foreign_key: :uploaded_by_id,
                                dependent: :nullify,
                                inverse_of: :uploaded_by
  has_many :recorded_transactions, class_name: "Transaction",
                                   foreign_key: :recorded_by_id,
                                   dependent: :restrict_with_error,
                                   inverse_of: :recorded_by
  has_many :tickets, dependent: :destroy
  has_many :ticket_comments, dependent: :destroy

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

  def staff?
    admin? || board? || treasurer?
  end
end
