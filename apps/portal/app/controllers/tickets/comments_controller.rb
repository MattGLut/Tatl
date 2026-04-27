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
        respond_to do |format|
          format.turbo_stream { render_comment_success }
          format.html { redirect_to tickets_ticket_path(@ticket), notice: "Comment was successfully added." }
        end
      else
        respond_to do |format|
          format.turbo_stream { render_comment_errors }
          format.html do
            @comments = @ticket.ticket_comments.includes(:user).chronological
            render "tickets/tickets/show", status: :unprocessable_content
          end
        end
      end
    end

    private

    def set_ticket
      @ticket = Ticket.find(params[:ticket_id])
    end

    def comment_params
      params.expect(ticket_comment: %i[body file])
    end

    def render_comment_success
      render turbo_stream: [
        turbo_stream.replace(
          helpers.dom_id(@ticket, :comment_form),
          partial: "tickets/tickets/comment_form",
          locals: { ticket: @ticket, comment: TicketComment.new }
        ),
        turbo_stream.remove(helpers.dom_id(@ticket, :no_comments))
      ]
    end

    def render_comment_errors
      render turbo_stream: turbo_stream.replace(
        helpers.dom_id(@ticket, :comment_form),
        partial: "tickets/tickets/comment_form",
        locals: { ticket: @ticket, comment: @comment }
      ), status: :unprocessable_content
    end
  end
end
