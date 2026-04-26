# frozen_string_literal: true

module Accounting
  class BudgetLinesController < BaseController
    before_action :set_budget_line, only: %i[edit update destroy]

    def index
      authorize BudgetLine, :index?, policy_class: Accounting::BudgetLinePolicy
      @budget_lines = policy_scope(BudgetLine, policy_scope_class: Accounting::BudgetLinePolicy::Scope)
                      .includes(:account)
                      .order(fiscal_year: :desc, created_at: :asc)
      @fiscal_year = params[:fiscal_year]&.to_i || Date.current.year
      @budget_lines = @budget_lines.for_year(@fiscal_year)
    end

    def new
      @budget_line = authorize BudgetLine.new, policy_class: Accounting::BudgetLinePolicy
    end

    def edit; end

    def create
      @budget_line = BudgetLine.new(budget_line_params)
      authorize @budget_line, policy_class: Accounting::BudgetLinePolicy

      if @budget_line.save
        redirect_to accounting_budget_lines_path(fiscal_year: @budget_line.fiscal_year),
                    notice: "Budget line was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @budget_line.update(budget_line_params)
        redirect_to accounting_budget_lines_path(fiscal_year: @budget_line.fiscal_year),
                    notice: "Budget line was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      fiscal_year = @budget_line.fiscal_year
      @budget_line.destroy!
      redirect_to accounting_budget_lines_path(fiscal_year: fiscal_year),
                  notice: "Budget line was successfully deleted.", status: :see_other
    end

    private

    def set_budget_line
      @budget_line = authorize BudgetLine.find(params[:id]), policy_class: Accounting::BudgetLinePolicy
    end

    def budget_line_params
      params.expect(budget_line: %i[account_id fiscal_year amount description])
    end
  end
end
