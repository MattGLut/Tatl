# frozen_string_literal: true

module Tickets
  class TicketsController < BaseController
    TICKET_FILTERS = { status: :by_status, category: :by_category, priority: :by_priority }.freeze

    after_action :verify_policy_scoped, only: :index
    before_action :set_ticket, only: %i[show update_status]

    def index
      authorize Ticket
      @tickets = filtered_tickets
    end

    def show
      @comments = @ticket.ticket_comments.includes(:user).chronological
      @comment = TicketComment.new
    end

    def new
      @ticket = authorize Ticket.new
      @properties = current_user_properties
    end

    def create
      @ticket = Ticket.new(ticket_params)
      @ticket.user = current_user
      authorize @ticket

      if @ticket.save
        TicketMailer.new_ticket_notification(@ticket).deliver_later
        redirect_to tickets_ticket_path(@ticket), notice: "Ticket was successfully created."
      else
        @properties = current_user_properties
        render :new, status: :unprocessable_content
      end
    end

    def update_status
      previous_status = @ticket.status

      unless @ticket.update(status_params)
        return redirect_to tickets_ticket_path(@ticket), alert: "Failed to update ticket status."
      end

      sync_closed_at
      TicketMailer.status_change_notification(@ticket).deliver_later if @ticket.status != previous_status
      redirect_to tickets_ticket_path(@ticket), notice: "Ticket status was successfully updated."
    end

    private

    def set_ticket
      @ticket = authorize Ticket.find(params[:id])
    end

    def ticket_params
      params.expect(ticket: %i[subject description category property_id])
    end

    def status_params
      params.expect(ticket: %i[status priority])
    end

    def filtered_tickets
      scope = policy_scope(Ticket).includes(:user, :property).recent
      TICKET_FILTERS.each do |param, method|
        scope = scope.public_send(method, params[param]) if params[param].present?
      end
      scope
    end

    def sync_closed_at
      @ticket.update!(closed_at: Time.current) if @ticket.closed? && @ticket.closed_at.nil?
      @ticket.update!(closed_at: nil) if @ticket.open? && @ticket.closed_at.present?
    end

    def current_user_properties
      if current_user.admin? || current_user.board? || current_user.treasurer?
        Property.order(:name)
      else
        current_user.properties
      end
    end
  end
end
