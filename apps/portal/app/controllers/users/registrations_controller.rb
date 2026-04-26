# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    def destroy
      authorize current_user, :destroy?
      super
    end

    protected

    # Allow profile-only updates (name, avatar) without requiring the current
    # password. Email changes and password changes still require it.
    def update_resource(resource, params)
      return super if password_required?(resource, params)

      params.delete(:current_password)
      resource.update_without_password(params)
    end

    private

    def password_required?(resource, params)
      params[:password].present? ||
        params[:password_confirmation].present? ||
        (params[:email].present? && params[:email] != resource.email)
    end
  end
end
