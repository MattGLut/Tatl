# frozen_string_literal: true

# Reusable Tailwind class strings for forms and UI (keeps ERB under erb_lint line length).
module FormClassHelper
  # Accounting-style text/select/textarea (rounded-md)
  def form_input_class
    "mt-1 block w-full rounded-md border border-slate-300 " \
      "dark:border-slate-600 dark:bg-slate-700 dark:text-slate-100 " \
      "px-3 py-2 shadow-sm focus:border-brand-500 focus:ring-brand-500 sm:text-sm"
  end

  # Devise and profile forms (rounded-lg, explicit focus:ring-1)
  def form_input_lg_class
    "mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 " \
      "text-sm shadow-sm focus:border-brand-500 focus:outline-none " \
      "focus:ring-1 focus:ring-brand-500 dark:border-slate-600 " \
      "dark:bg-slate-700 dark:text-slate-100"
  end

  def form_cancel_link_class
    "rounded-md border border-slate-300 dark:border-slate-600 px-4 py-2 text-sm " \
      "hover:bg-slate-100 dark:hover:bg-slate-700"
  end

  # Property, document, and membership forms (focus:ring-brand-500, text-sm)
  def form_input_shadow_class
    "mt-1 block w-full rounded-md border border-slate-300 px-3 py-2 " \
      "text-sm shadow-sm focus:border-brand-500 focus:ring-brand-500 " \
      "dark:border-slate-600 dark:bg-slate-700 dark:text-slate-100"
  end

  def document_file_input_class
    "mt-1 block w-full text-sm text-slate-500 " \
      "file:mr-4 file:rounded-md file:border-0 file:bg-brand-50 " \
      "file:px-4 file:py-2 file:text-sm file:font-medium file:text-brand-700 " \
      "hover:file:bg-brand-100 dark:text-slate-400 dark:file:bg-brand-900/30 " \
      "dark:file:text-brand-400 dark:hover:file:bg-brand-900/50"
  end

  def ticket_admin_select_class
    "mt-1 block rounded-md border border-slate-300 px-3 py-2 text-sm shadow-sm " \
      "focus:border-brand-500 focus:ring-brand-500 dark:border-slate-600 " \
      "dark:bg-slate-700 dark:text-slate-100"
  end

  def comment_text_area_class
    "block w-full rounded-md border border-slate-300 px-3 py-2 text-sm shadow-sm " \
      "focus:border-brand-500 focus:ring-brand-500 dark:border-slate-600 " \
      "dark:bg-slate-700 dark:text-slate-100"
  end

  def tickets_filter_clear_link_class
    "inline-flex h-9 items-center rounded-md border border-slate-300 px-3 " \
      "text-sm font-medium text-slate-700 shadow-sm hover:bg-slate-50 " \
      "dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
  end

  def tickets_status_tab_active_class
    "rounded-md px-3 py-1.5 text-sm font-medium bg-brand-600 text-white"
  end

  def tickets_status_tab_inactive_class
    "rounded-md px-3 py-1.5 text-sm font-medium border border-slate-300 " \
      "text-slate-700 hover:bg-slate-100 dark:border-slate-600 dark:text-slate-300 " \
      "dark:hover:bg-slate-700"
  end

  def mobile_sign_out_button_class
    "mt-1 w-full cursor-pointer rounded-md border-0 bg-transparent px-2 py-2 " \
      "text-left text-sm text-[var(--color-text-secondary)] " \
      "hover:bg-[var(--color-surface-hover)]"
  end

  def dashboard_ticket_link_class
    "block rounded-lg border border-slate-100 bg-slate-50/60 px-3 py-2 " \
      "text-sm transition hover:border-brand-200 hover:bg-white " \
      "dark:border-slate-700 dark:bg-slate-700/40 dark:hover:border-brand-700 " \
      "dark:hover:bg-slate-700"
  end

  def form_file_input_class
    "mt-1 block w-full text-sm text-slate-500 dark:text-slate-400 " \
      "file:mr-4 file:rounded-md file:border-0 file:bg-brand-50 " \
      "file:px-3 file:py-2 file:text-sm file:font-medium file:text-brand-700 " \
      "hover:file:bg-brand-100 dark:file:bg-brand-900/40 dark:file:text-brand-400 " \
      "dark:hover:file:bg-brand-900/60"
  end

  def registration_file_field_class
    "block w-full text-sm text-slate-700 " \
      "file:mr-3 file:rounded-md file:border-0 file:bg-slate-100 " \
      "file:px-3 file:py-1.5 file:text-sm file:font-medium file:text-slate-700 " \
      "hover:file:bg-slate-200 dark:text-slate-300 dark:file:bg-slate-700 " \
      "dark:file:text-slate-300 dark:hover:file:bg-slate-600"
  end

  def theme_appearance_mode_button_class
    "inline-flex cursor-pointer items-center gap-2 rounded-lg border " \
      "border-slate-300 px-4 py-2.5 text-sm font-medium text-slate-700 " \
      "transition-colors hover:bg-slate-100 " \
      "focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 " \
      "focus-visible:ring-offset-2 " \
      "aria-pressed:border-brand-600 aria-pressed:bg-brand-600 aria-pressed:text-white " \
      "dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700 " \
      "dark:aria-pressed:border-brand-600 dark:aria-pressed:bg-brand-600 " \
      "dark:aria-pressed:text-white"
  end

  def devise_form_submit_class
    "rounded-lg bg-brand-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm " \
      "hover:bg-brand-700 focus:outline-none focus:ring-2 " \
      "focus:ring-brand-500 focus:ring-offset-2 cursor-pointer"
  end

  def devise_wfull_submit_class
    "w-full rounded-lg bg-brand-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm " \
      "hover:bg-brand-700 focus:outline-none focus:ring-2 " \
      "focus:ring-brand-500 focus:ring-offset-2 cursor-pointer"
  end
end
