# frozen_string_literal: true

module Accounting
  class DuesAssessmentsController < BaseController
    before_action :set_assessment, only: %i[show edit update destroy]

    def index
      authorize DuesAssessment, :index?, policy_class: Accounting::DuesAssessmentPolicy
      @assessments = policy_scope(DuesAssessment, policy_scope_class: Accounting::DuesAssessmentPolicy::Scope)
                     .includes(:property, :dues_payments)
                     .order(due_date: :desc)
      @assessments = @assessments.for_property(params[:property_id]) if params[:property_id].present?
    end

    def show
      @payments = @assessment.dues_payments.order(paid_on: :desc)
    end

    def new
      @assessment = authorize DuesAssessment.new, policy_class: Accounting::DuesAssessmentPolicy
    end

    def edit; end

    def create
      @assessment = DuesAssessment.new(assessment_params)
      authorize @assessment, policy_class: Accounting::DuesAssessmentPolicy

      if @assessment.save
        redirect_to accounting_dues_assessment_path(@assessment), notice: "Dues assessment was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @assessment.update(assessment_params)
        redirect_to accounting_dues_assessment_path(@assessment), notice: "Dues assessment was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @assessment.destroy!
      redirect_to accounting_dues_assessments_path, notice: "Dues assessment was successfully deleted.",
                                                    status: :see_other
    end

    private

    def set_assessment
      @assessment = authorize DuesAssessment.find(params[:id]), policy_class: Accounting::DuesAssessmentPolicy
    end

    def assessment_params
      params.expect(dues_assessment: %i[property_id amount period_start period_end due_date description status])
    end
  end
end
