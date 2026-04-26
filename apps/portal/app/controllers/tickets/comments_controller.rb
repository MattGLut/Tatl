# frozen_string_literal: true

module Tickets
  class CommentsController < BaseController
    before_action :set_ticket

    def create
      @comment = @ticket.ticket_comments.build(comment_params)
      @comment.user = current_user
      authorize @comment

      if @comment.save
        TicketMailer.new_comment_notification(@comment).deliver_later
        redirect_to tickets_ticket_path(@ticket), notice: "Comment was successfully added."
      else
        @comments = @ticket.ticket_comments.includes(:user).chronological
        render "tickets/tickets/show", status: :unprocessable_content
      end
    end

    private

    def set_ticket
      @ticket = Ticket.find(params[:ticket_id])
    end

    def comment_params
      params.expect(ticket_comment: %i[body file])
    end
  end
end
