# frozen_string_literal: true

module Tickets
  module TicketsHelper
    FILTER_PARAM_KEYS = %i[
      status
      category
      priority
      created_on_or_after
      created_on_or_before
      user_id
      sort
      dir
    ].freeze

    def tickets_index_path_params(extra = {})
      FILTER_PARAM_KEYS.index_with { |k| params[k] }
        .merge(extra)
        .compact_blank
    end
  end
end
