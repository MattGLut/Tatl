# frozen_string_literal: true

module Sortable
  extend ActiveSupport::Concern

  private

  # Apply a whitelisted ORDER BY to +scope+ based on params[:sort] and params[:dir].
  #
  # +allowed+ is a Hash mapping the public sort key (string) to either a column
  # symbol on the scope's table or a SQL fragment for joined columns
  # (e.g. "properties.name"). Anything not in the whitelist falls back to
  # +default+, which is itself a Hash passed straight to .order.
  def apply_sort(scope, allowed:, default:)
    key = params[:sort].to_s
    direction = params[:dir].to_s == "asc" ? :asc : :desc

    if allowed.key?(key)
      scope.order(allowed.fetch(key) => direction)
    else
      scope.order(default)
    end
  end
end
