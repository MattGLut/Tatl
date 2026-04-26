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

  has_one_attached :avatar

  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  AVATAR_MAX_BYTES = 5.megabytes

  attr_accessor :remove_avatar

  enum :role, {
    resident: 0,
    board: 1,
    treasurer: 2,
    admin: 3
  }, default: :resident, validate: true

  validates :first_name, :last_name, presence: true
  validate :acceptable_avatar

  after_save :purge_avatar_if_requested

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  def display_name
    full_name.presence || email
  end

  def initials
    parts = [first_name, last_name].compact_blank
    return parts.map { |s| s[0].to_s.upcase }.join if parts.any?

    email.to_s[0].to_s.upcase
  end

  def staff?
    admin? || board? || treasurer?
  end

  private

  def acceptable_avatar
    return unless avatar.attached?

    unless AVATAR_CONTENT_TYPES.include?(avatar.content_type)
      errors.add(:avatar, "must be a PNG, JPEG, GIF, or WebP image")
    end

    return unless avatar.byte_size > AVATAR_MAX_BYTES

    errors.add(:avatar, "must be smaller than 5 MB")
  end

  def purge_avatar_if_requested
    return unless ActiveModel::Type::Boolean.new.cast(remove_avatar)
    return unless avatar.attached?

    avatar.purge_later
  end
end
