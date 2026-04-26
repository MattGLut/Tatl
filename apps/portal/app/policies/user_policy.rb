# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def destroy?
    false
  end
end
