# frozen_string_literal: true

class AnnouncementMailer < ApplicationMailer
  def new_announcement(announcement, recipient)
    @announcement = announcement

    mail(
      to: recipient.email,
      subject: "New community announcement: #{announcement.title}"
    )
  end
end
