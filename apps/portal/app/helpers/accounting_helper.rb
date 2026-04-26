# frozen_string_literal: true

module AccountingHelper
  ASSESSMENT_STATUS_CLASSES = {
    "open" => "bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300",
    "partial" => "bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300",
    "paid" => "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300",
    "overdue" => "bg-rose-100 text-rose-800 dark:bg-rose-900/40 dark:text-rose-300"
  }.freeze

  AGING_BUCKET_LABELS = {
    current: "Current",
    "30_days": "1-30 Days",
    "60_days": "31-60 Days",
    "90_plus": "90+ Days"
  }.freeze

  AGING_BUCKET_CLASSES = {
    current: "border-blue-200 bg-blue-50 dark:border-blue-800 dark:bg-blue-900/30",
    "30_days": "border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-900/30",
    "60_days": "border-orange-200 bg-orange-50 dark:border-orange-800 dark:bg-orange-900/30",
    "90_plus": "border-rose-200 bg-rose-50 dark:border-rose-800 dark:bg-rose-900/30"
  }.freeze

  def assessment_status_class(status)
    ASSESSMENT_STATUS_CLASSES.fetch(status, "bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300")
  end

  def aging_bucket_label(bucket)
    AGING_BUCKET_LABELS.fetch(bucket, bucket.to_s.titleize)
  end

  def aging_bucket_class(bucket)
    AGING_BUCKET_CLASSES.fetch(bucket, "border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800")
  end
end
