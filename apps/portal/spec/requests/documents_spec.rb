# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Documents" do
  let(:admin) { create(:user, :admin) }
  let(:board_member) { create(:user, :board) }
  let(:resident) { create(:user) }

  let(:pdf_file) do
    Rack::Test::UploadedFile.new(StringIO.new("fake pdf"), "application/pdf", true, original_filename: "test.pdf")
  end

  describe "GET /documents" do
    it "requires authentication" do
      get documents_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows all documents to staff" do
      create(:document, title: "HOA Bylaws")
      create(:document, :draft, title: "Draft Policy")

      sign_in admin
      get documents_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("HOA Bylaws")
      expect(response.body).to include("Draft Policy")
    end

    it "shows only published documents to residents" do
      create(:document, title: "Published Doc")
      create(:document, :draft, title: "Secret Draft")

      sign_in resident
      get documents_path
      expect(response.body).to include("Published Doc")
      expect(response.body).not_to include("Secret Draft")
    end

    it "filters by category" do
      create(:document, :bylaws, title: "Bylaws Doc")
      create(:document, :minutes, title: "Minutes Doc")

      sign_in admin
      get documents_path(category: "bylaws")
      expect(response.body).to include("Bylaws Doc")
      expect(response.body).not_to include("Minutes Doc")
    end

    describe "sorting" do
      it "orders by title when sort=title&dir=asc" do
        create(:document, title: "Zeta Doc")
        create(:document, title: "Alpha Doc")

        sign_in admin
        get documents_path(sort: "title", dir: "asc")
        expect(response.body.index("Alpha Doc")).to be < response.body.index("Zeta Doc")
      end

      it "ignores unknown sort keys" do
        sign_in admin
        get documents_path(sort: "; bad")
        expect(response).to have_http_status(:ok)
      end
    end

    describe "pagination" do
      around { |ex| with_pagy_limit(3) { ex.run } }

      it "limits to page size" do
        create_list(:document, 5)
        sign_in admin
        get documents_path
        expect(response.body.scan('<tr class="hover:bg-slate-50">').size).to eq(3)
      end

      it "renders the next page" do
        create_list(:document, 5)
        sign_in admin
        get documents_path(page: 2)
        expect(response.body.scan('<tr class="hover:bg-slate-50">').size).to eq(2)
      end
    end
  end

  describe "GET /documents/:id" do
    it "allows staff to view any document" do
      doc = create(:document, :draft)
      sign_in admin
      get document_path(doc)
      expect(response).to have_http_status(:ok)
    end

    it "allows residents to view published documents" do
      doc = create(:document)
      sign_in resident
      get document_path(doc)
      expect(response).to have_http_status(:ok)
    end

    it "denies residents access to draft documents" do
      doc = create(:document, :draft)
      sign_in resident
      get document_path(doc)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /documents/new" do
    it "renders the form for staff" do
      sign_in board_member
      get new_document_path
      expect(response).to have_http_status(:ok)
    end

    it "denies access to residents" do
      sign_in resident
      get new_document_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /documents" do
    let(:valid_params) do
      {
        document: {
          title: "New Policy",
          category: "policy",
          description: "A new policy document",
          file: Rack::Test::UploadedFile.new(StringIO.new("content"), "application/pdf", true,
                                             original_filename: "policy.pdf")
        }
      }
    end

    it "creates a document for staff" do
      sign_in admin
      expect { post documents_path, params: valid_params }.to change(Document, :count).by(1)

      doc = Document.last
      expect(doc.uploaded_by).to eq(admin)
      expect(doc.file).to be_attached
      expect(response).to redirect_to(document_path(doc))
    end

    it "re-renders on invalid data" do
      sign_in admin
      post documents_path, params: { document: { title: "", category: "policy" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "denies creation for residents" do
      sign_in resident
      post documents_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /documents/:id" do
    let!(:document) { create(:document) }

    it "destroys for staff" do
      sign_in admin
      expect { delete document_path(document) }.to change(Document, :count).by(-1)
      expect(response).to redirect_to(documents_path)
    end

    it "denies deletion for residents" do
      sign_in resident
      delete document_path(document)
      expect(response).to redirect_to(root_path)
    end
  end
end
