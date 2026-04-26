# frozen_string_literal: true

module Accounting
  class DuesPaymentsController < BaseController
    before_action :set_assessment

    def new
      @payment = authorize DuesPayment.new(dues_assessment: @assessment), policy_class: Accounting::DuesPaymentPolicy
    end

    def create
      @payment = DuesPayment.new(payment_params)
      @payment.dues_assessment = @assessment
      authorize @payment, policy_class: Accounting::DuesPaymentPolicy

      if @payment.save
        redirect_to accounting_dues_assessment_path(@assessment), notice: "Payment was successfully recorded."
      else
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      @payment = authorize @assessment.dues_payments.find(params[:id]), policy_class: Accounting::DuesPaymentPolicy
      @payment.destroy!
      redirect_to accounting_dues_assessment_path(@assessment), notice: "Payment was successfully removed.",
                                                                status: :see_other
    end

    private

    def set_assessment
      @assessment = DuesAssessment.find(params[:dues_assessment_id])
    end

    def payment_params
      params.expect(dues_payment: %i[amount paid_on reference])
    end
  end
end
