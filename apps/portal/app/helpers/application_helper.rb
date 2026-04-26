# frozen_string_literal: true

module ApplicationHelper
  include FormClassHelper

  def filter_clear_link_class
    "inline-flex h-9 items-center rounded-md border border-slate-300 " \
      "dark:border-slate-600 px-3 text-sm font-medium text-slate-700 " \
      "dark:text-slate-300 shadow-sm hover:bg-slate-50 dark:hover:bg-slate-700/50"
  end

  def filter_form_control_class
    "block h-9 w-full rounded-md border border-slate-300 bg-white px-2.5 text-sm " \
      "text-slate-900 focus:border-brand-500 focus:ring-1 focus:ring-brand-500 " \
      "dark:border-slate-600 dark:bg-slate-700 dark:text-slate-100"
  end
end
