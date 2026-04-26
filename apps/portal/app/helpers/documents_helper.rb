# frozen_string_literal: true

module DocumentsHelper
  def document_category_filter_pill_class(active:)
    base = "whitespace-nowrap rounded-md px-3 py-1.5 text-sm font-medium"
    if active
      "#{base} bg-brand-600 text-white"
    else
      "#{base} border border-slate-300 text-slate-700 hover:bg-slate-100 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
    end
  end
end
