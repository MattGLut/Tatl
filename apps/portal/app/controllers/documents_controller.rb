# frozen_string_literal: true

class DocumentsController < ApplicationController
  DOCUMENT_SORTS = {
    "title" => :title,
    "category" => :category,
    "published_at" => :published_at,
    "created_at" => :created_at
  }.freeze

  before_action :authenticate_user!
  before_action :set_document, only: %i[show destroy]

  def index
    authorize Document
    scope = policy_scope(Document)
    scope = scope.by_category(params[:category]) if params[:category].present?
    scope = apply_sort(scope, allowed: DOCUMENT_SORTS, default: { created_at: :desc })
    @pagy, @documents = pagy(scope)
  end

  def show; end

  def new
    @document = authorize Document.new
  end

  def create
    @document = Document.new(document_params)
    @document.uploaded_by = current_user
    authorize @document

    if @document.save
      redirect_to @document, notice: "Document was successfully uploaded."
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @document.destroy!
    redirect_to documents_path, notice: "Document was successfully deleted.", status: :see_other
  end

  private

  def set_document
    @document = authorize Document.find(params.expect(:id))
  end

  def document_params
    params.expect(document: %i[title description category published_at file])
  end
end
