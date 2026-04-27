# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Announcements" do
  let(:admin) { create(:user, :admin) }
  let(:resident) { create(:user) }
  let!(:announcement) { create(:announcement, title: "Water Shutoff Notice") }

  describe "GET /admin/announcements" do
    it "requires authentication" do
      get admin_announcements_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows admin access" do
      sign_in admin
      get admin_announcements_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Water Shutoff Notice")
    end

    it "denies non-admin access" do
      sign_in resident
      get admin_announcements_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/announcements" do
    let(:valid_params) do
      {
        announcement: {
          title: "Clubhouse Closed",
          body: "The clubhouse will be closed this weekend.",
          active: true,
          pinned_until: 2.days.from_now
        }
      }
    end

    it "creates an announcement for admins" do
      sign_in admin
      expect { post admin_announcements_path, params: valid_params }.to change(Announcement, :count).by(1)
      expect(response).to redirect_to(admin_announcements_path)
    end

    it "enqueues announcement emails when requested" do
      opted_in = create(:user, email: "opted-in@tatl.example")
      opted_out = create(:user, email: "opted-out@tatl.example", announcement_emails_enabled: false)

      sign_in admin
      expect do
        post admin_announcements_path, params: valid_params.deep_merge(
          announcement: { send_email_notification: "1" }
        )
      end.to have_enqueued_mail(AnnouncementMailer, :new_announcement).with(
        an_instance_of(Announcement),
        opted_in
      )

      expect(Announcement.last).to be_present
      expect(
        enqueued_jobs.any? do |job|
          args = job[:args] || []
          args.inspect.include?("opted-out@tatl.example")
        end
      ).to eq(false)
      expect(opted_out.announcement_emails_enabled).to be(false)
    end

    it "re-renders on invalid data" do
      sign_in admin
      post admin_announcements_path, params: { announcement: { title: "", body: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "denies non-admin users" do
      sign_in resident
      post admin_announcements_path, params: valid_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /admin/announcements/:id" do
    it "updates an announcement for admins" do
      sign_in admin
      patch admin_announcement_path(announcement), params: { announcement: { title: "Updated Title" } }

      expect(response).to redirect_to(admin_announcements_path)
      expect(announcement.reload.title).to eq("Updated Title")
    end
  end

  describe "DELETE /admin/announcements/:id" do
    it "destroys an announcement for admins" do
      sign_in admin
      expect { delete admin_announcement_path(announcement) }.to change(Announcement, :count).by(-1)
      expect(response).to redirect_to(admin_announcements_path)
    end
  end

  describe "banner rendering on signed-in pages" do
    it "shows visible announcement banner to signed-in users" do
      sign_in resident
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Water Shutoff Notice")
    end

    it "does not show inactive announcements in banner" do
      announcement.update!(active: false)
      sign_in resident
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Water Shutoff Notice")
    end
  end
end
