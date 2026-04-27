# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounting::DuesAssessments" do
  def first_table_tbody_text(response)
    Nokogiri::HTML(response.body).at_css("div.mt-6 table tbody")&.text || ""
  end

  let(:admin) { create(:user, :admin) }
  let(:treasurer) { create(:user, :treasurer) }
  let(:resident) { create(:user) }
  let(:property) { create(:property) }

  describe "GET /accounting/dues" do
    it "requires authentication" do
      get accounting_dues_assessments_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists all assessments for staff" do
      create(:dues_assessment, property: property)
      sign_in treasurer
      get accounting_dues_assessments_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(property.name)
    end

    it "lists only own-property assessments for residents" do
      own_prop = create(:property, name: "My Lot")
      other_prop = create(:property, name: "Other Lot")
      create(:membership, user: resident, property: own_prop)
      create(:dues_assessment, property: own_prop)
      create(:dues_assessment, property: other_prop)

      sign_in resident
      get accounting_dues_assessments_path
      expect(response.body).to include("My Lot")
      expect(response.body).not_to include("Other Lot")
    end

    it "filters by property_id" do
      a = create(:property, name: "Alpha Ave")
      b = create(:property, name: "Beta Blvd")
      create(:dues_assessment, property: a)
      create(:dues_assessment, property: b)

      sign_in treasurer
      get accounting_dues_assessments_path(property_id: a.id)
      tbody = first_table_tbody_text(response)
      expect(tbody).to include("Alpha Ave")
      expect(tbody).not_to include("Beta Blvd")
    end

    it "filters by status" do
      own_name = "OpenStatus Alpha Prop"
      drop_name = "OpenStatus Beta Prop"
      create(:dues_assessment, status: :open, property: create(:property, name: own_name))
      create(:dues_assessment, :paid, property: create(:property, name: drop_name))

      sign_in treasurer
      get accounting_dues_assessments_path(status: "open")
      tbody = first_table_tbody_text(response)
      expect(tbody).to include(own_name)
      expect(tbody).not_to include(drop_name)
    end

    it "filters by due date range" do
      in_p = create(:property, name: "Due range keep prop")
      out_p = create(:property, name: "Due range skip prop")
      create(:dues_assessment, property: in_p, due_date: Date.new(2026, 2, 10))
      create(:dues_assessment, property: out_p, due_date: Date.new(2026, 6, 1))
      sign_in treasurer
      get accounting_dues_assessments_path(due_on_or_after: "2026-02-01", due_on_or_before: "2026-02-28")
      tbody = first_table_tbody_text(response)
      expect(tbody).to include(in_p.name)
      expect(tbody).not_to include(out_p.name)
    end

    it "invalid status param does not error and lists all" do
      create(:dues_assessment, property: property)
      sign_in treasurer
      get accounting_dues_assessments_path(status: "nope")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(property.name)
    end

    it "ignores invalid due date filter params" do
      create(:dues_assessment, property: property)
      sign_in treasurer
      get accounting_dues_assessments_path(due_on_or_after: "nope", due_on_or_before: "bad")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(property.name)
    end

    describe "sorting" do
      it "sorts by joined property name" do
        create(:dues_assessment, property: create(:property, name: "Zeta House"))
        create(:dues_assessment, property: create(:property, name: "Alpha House"))

        sign_in treasurer
        get accounting_dues_assessments_path(sort: "property", dir: "asc")
        expect(response.body.index("Alpha House")).to be < response.body.index("Zeta House")
      end

      it "ignores unknown sort keys" do
        sign_in treasurer
        get accounting_dues_assessments_path(sort: "drop")
        expect(response).to have_http_status(:ok)
      end
    end

    describe "pagination" do
      around { |ex| with_pagy_limit(3) { ex.run } }

      it "limits results to one page" do
        create_list(:dues_assessment, 5, property: property)
        sign_in treasurer
        get accounting_dues_assessments_path
        # 3 body rows + 1 thead row
        expect(response.body.scan("<tr>").size).to eq(4)
      end

      it "renders subsequent pages" do
        create_list(:dues_assessment, 5, property: property)
        sign_in treasurer
        get accounting_dues_assessments_path(page: 2)
        # 2 remaining body rows + 1 thead row
        expect(response.body.scan("<tr>").size).to eq(3)
      end

      it "keeps property filter in pagination next link" do
        p2 = create(:property, name: "Only This")
        with_pagy_limit(1) do
          create_list(:dues_assessment, 2, property: p2, description: "Row")

          sign_in treasurer
          get accounting_dues_assessments_path(property_id: p2.id, sort: "due_date", dir: "desc")
        end
        expect(response.body).to include("Next")
        expect(response.body).to include("property_id=")
        expect(response.body).to include(p2.id.to_s)
      end
    end
  end

  describe "GET /accounting/dues/:id" do
    let(:assessment) { create(:dues_assessment, property: property) }

    it "shows details to staff" do
      sign_in admin
      get accounting_dues_assessment_path(assessment)
      expect(response).to have_http_status(:ok)
    end

    it "shows details to resident with membership" do
      create(:membership, user: resident, property: property)
      sign_in resident
      get accounting_dues_assessment_path(assessment)
      expect(response).to have_http_status(:ok)
    end

    it "denies access to resident without membership" do
      sign_in resident
      get accounting_dues_assessment_path(assessment)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /accounting/dues/new" do
    it "renders the form for staff" do
      sign_in treasurer
      get new_accounting_dues_assessment_path
      expect(response).to have_http_status(:ok)
    end

    it "denies access to residents" do
      sign_in resident
      get new_accounting_dues_assessment_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /accounting/dues/:id/edit" do
    let(:assessment) { create(:dues_assessment, property: property, description: "Editable row") }

    it "renders the form for staff" do
      sign_in treasurer
      get edit_accounting_dues_assessment_path(assessment)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Editable row")
    end

    it "denies access to residents" do
      sign_in resident
      get edit_accounting_dues_assessment_path(assessment)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /accounting/dues" do
    let(:valid_params) do
      {
        dues_assessment: {
          property_id: property.id, amount: "250.00",
          period_start: Date.current.beginning_of_quarter,
          period_end: Date.current.end_of_quarter,
          due_date: Date.current + 30, description: "Q2 Dues"
        }
      }
    end

    it "creates an assessment for staff" do
      sign_in treasurer
      expect { post accounting_dues_assessments_path, params: valid_params }.to change(DuesAssessment, :count).by(1)
      expect(response).to redirect_to(accounting_dues_assessment_path(DuesAssessment.last))
    end

    it "denies creation for residents" do
      sign_in resident
      post accounting_dues_assessments_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /accounting/dues/:id" do
    let(:assessment) { create(:dues_assessment, property: property, description: "Before") }
    let(:patch_params) do
      {
        dues_assessment: {
          property_id: assessment.property_id,
          amount: "250.00",
          period_start: assessment.period_start,
          period_end: assessment.period_end,
          due_date: assessment.due_date,
          description: "After patch",
          status: assessment.status
        }
      }
    end

    it "updates for staff" do
      sign_in treasurer
      patch accounting_dues_assessment_path(assessment), params: patch_params
      expect(response).to redirect_to(accounting_dues_assessment_path(assessment))
      expect(assessment.reload.description).to eq("After patch")
    end

    it "denies update for residents" do
      sign_in resident
      patch accounting_dues_assessment_path(assessment), params: patch_params
      expect(response).to redirect_to(root_path)
      expect(assessment.reload.description).to eq("Before")
    end
  end

  describe "DELETE /accounting/dues/:id" do
    let!(:assessment) { create(:dues_assessment) }

    it "deletes for admins" do
      sign_in admin
      expect { delete accounting_dues_assessment_path(assessment) }.to change(DuesAssessment, :count).by(-1)
    end

    it "denies deletion for treasurer" do
      sign_in treasurer
      delete accounting_dues_assessment_path(assessment)
      expect(response).to redirect_to(root_path)
    end
  end
end
