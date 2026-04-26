# frozen_string_literal: true

class TicketMailer < ApplicationMailer
  def new_ticket_notification(ticket)
    @ticket = ticket
    admin_emails = User.where(role: :admin).pluck(:email)
    return if admin_emails.empty?

    mail(to: admin_emails, subject: "New ticket: #{ticket.subject}")
  end

  def status_change_notification(ticket)
    @ticket = ticket
    mail(to: ticket.user.email, subject: "Ticket updated: #{ticket.subject}")
  end

  def new_comment_notification(comment)
    @comment = comment
    @ticket = comment.ticket

    recipient = if comment.user_id == @ticket.user_id
                  User.where(role: :admin).pluck(:email)
                else
                  @ticket.user.email
                end

    return if recipient.blank?

    mail(to: recipient, subject: "New comment on: #{@ticket.subject}")
  end
end
