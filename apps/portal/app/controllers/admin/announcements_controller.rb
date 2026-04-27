# frozen_string_literal: true

module Admin
  class AnnouncementsController < BaseController
    before_action :set_announcement, only: %i[show edit update destroy]

    def index
      authorize Announcement
      @announcements = policy_scope(Announcement).order(created_at: :desc)
    end

    def show; end

    def new
      @announcement = authorize Announcement.new
    end

    def create
      @announcement = Announcement.new(announcement_params)
      authorize @announcement

      if @announcement.save
        send_announcement_emails! if send_email_notification?
        redirect_to admin_announcements_path, notice: "Announcement was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @announcement.update(announcement_params)
        redirect_to admin_announcements_path, notice: "Announcement was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @announcement.destroy!
      redirect_to admin_announcements_path, notice: "Announcement was successfully deleted.", status: :see_other
    end

    private

    def set_announcement
      @announcement = authorize Announcement.find(params[:id])
    end

    def announcement_params
      params.expect(announcement: %i[title body active pinned_until])
    end

    def send_email_notification?
      ActiveModel::Type::Boolean.new.cast(params.dig(:announcement, :send_email_notification))
    end

    def send_announcement_emails!
      User.announcement_email_enabled.find_each do |recipient|
        AnnouncementMailer.new_announcement(@announcement, recipient).deliver_later
      end
    end
  end
end
