# frozen_string_literal: true

class PropertiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property, only: %i[show edit update destroy]

  def index
    authorize Property
    @properties = policy_scope(Property).order(:name)
  end

  def show; end

  def new
    @property = authorize Property.new
  end

  def edit; end

  def create
    @property = authorize Property.new(property_params)

    if @property.save
      redirect_to @property, notice: "Property was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @property.update(property_params)
      redirect_to @property, notice: "Property was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @property.destroy!
    redirect_to properties_path, notice: "Property was successfully deleted.", status: :see_other
  end

  private

  def set_property
    @property = authorize Property.find(params[:id])
  end

  def property_params
    params.expect(property: %i[name street_address city state zip lot_number property_type notes])
  end
end
