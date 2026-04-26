# frozen_string_literal: true

class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property
  before_action :set_membership, only: %i[edit update destroy]

  def new
    @membership = authorize @property.memberships.build(started_on: Date.current)
  end

  def edit; end

  def create
    @membership = @property.memberships.build(membership_params)
    authorize @membership

    if @membership.save
      redirect_to @property, notice: "Membership was successfully added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @membership.update(membership_params)
      redirect_to @property, notice: "Membership was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @membership.destroy!
    redirect_to @property, notice: "Membership was successfully removed.", status: :see_other
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_membership
    @membership = authorize @property.memberships.find(params[:id])
  end

  def membership_params
    params.expect(membership: %i[user_id role started_on ended_on])
  end
end
