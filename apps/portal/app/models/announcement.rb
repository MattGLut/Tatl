# frozen_string_literal: true

class Announcement < ApplicationRecord
  validates :title, presence: true, length: { maximum: 120 }
  validates :body, presence: true, length: { maximum: 1_000 }

  scope :active_now, -> { where(active: true) }
  scope :currently_pinned, -> { where("pinned_until IS NULL OR pinned_until >= ?", Time.current) }
  scope :visible, lambda {
    active_now
      .currently_pinned
      .order(Arel.sql("pinned_until DESC NULLS LAST, created_at DESC"))
  }
end
