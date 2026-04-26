# frozen_string_literal: true

module SortableHelper
  DEFAULT_TH_CLASS = "px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-500"

  # Render a <th> whose label links back to the current page with sort/dir
  # query params toggled. Existing query params (filters, etc.) are preserved;
  # the page param is dropped so a sort change always goes back to page 1.
  def sortable_th(column, label, default_dir: :asc, th_class: DEFAULT_TH_CLASS)
    column_str = column.to_s
    active = params[:sort].to_s == column_str
    current_dir = params[:dir].to_s == "asc" ? "asc" : "desc"

    next_dir, caret = sortable_next_direction(active, current_dir, default_dir)
    sort_url = sortable_url_for(column_str, next_dir)

    link = link_to(sort_url, class: "inline-flex items-center gap-1 hover:text-slate-700") do
      safe_join([label, sortable_caret(active, caret)], " ")
    end

    content_tag(:th, link, class: th_class)
  end

  private

  def sortable_next_direction(active, current_dir, default_dir)
    if active
      next_dir = current_dir == "asc" ? "desc" : "asc"
      caret = current_dir == "asc" ? "\u2191" : "\u2193"
      [next_dir, caret]
    else
      [default_dir.to_s, "\u2195"]
    end
  end

  def sortable_caret(active, caret)
    classes = active ? "text-slate-700" : "text-slate-300"
    content_tag(:span, caret, class: classes, "aria-hidden": true)
  end

  def sortable_url_for(column_str, next_dir)
    new_params = request.query_parameters.merge("sort" => column_str, "dir" => next_dir).except("page")
    query = new_params.to_query
    query.empty? ? request.path : "#{request.path}?#{query}"
  end
end
