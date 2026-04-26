# frozen_string_literal: true

class DocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document, only: %i[show destroy]

  def index
    authorize Document
    @documents = policy_scope(Document).recent
    @documents = @documents.by_category(params[:category]) if params[:category].present?
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
    @document = authorize Document.find(params[:id])
  end

  def document_params
    params.expect(document: %i[title description category published_at file])
  end
end
