# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    load_signed_in_dashboard if user_signed_in?
  end

  private

  def load_signed_in_dashboard
    load_dashboard_properties
    load_dashboard_tickets
    load_dashboard_documents
    load_dashboard_dues
  end

  def load_dashboard_properties
    authorize Property, :index?
    @properties = policy_scope(Property).order(:name).limit(8)
  end

  def load_dashboard_tickets
    authorize Ticket, :index?
    base_tickets = policy_scope(Ticket).includes(:property, :user)
    @active_ticket_count = base_tickets.active.count
    @recent_tickets = base_tickets.recent.limit(6)
  end

  def load_dashboard_documents
    authorize Document, :index?
    @recent_documents = policy_scope(Document).includes(:uploaded_by).recent.limit(4)
  end

  def load_dashboard_dues
    authorize DuesAssessment, :index?, policy_class: Accounting::DuesAssessmentPolicy
    da_scope = policy_scope(
      DuesAssessment,
      policy_scope_class: Accounting::DuesAssessmentPolicy::Scope
    ).includes(:property)
    @dues_outstanding = da_scope.open_or_partial.order(due_date: :asc).limit(5)
    @dues_overdue_count = da_scope.overdue.count
  end
end
