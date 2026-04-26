# frozen_string_literal: true

module AvatarHelper
  # leading-none: capitals sit on a tight line box so flex/grid centering looks
  # visually correct inside a circle (default line-height skews vertically).
  AVATAR_SIZE_CLASSES = {
    sm: "h-8 w-8 text-xs leading-none",
    md: "h-16 w-16 text-lg leading-none",
    lg: "h-24 w-24 text-2xl leading-none"
  }.freeze

  AVATAR_PALETTE = %w[
    bg-brand-100
    bg-emerald-100
    bg-amber-100
    bg-rose-100
    bg-sky-100
    bg-violet-100
    bg-indigo-100
  ].freeze

  AVATAR_INK = %w[
    text-brand-700
    text-emerald-700
    text-amber-700
    text-rose-700
    text-sky-700
    text-violet-700
    text-indigo-700
  ].freeze

  def avatar_size_class(size)
    AVATAR_SIZE_CLASSES.fetch(size&.to_sym || :sm, AVATAR_SIZE_CLASSES[:sm])
  end

  def avatar_initials_classes(user)
    idx = (user.id || user.email.to_s.sum) % AVATAR_PALETTE.length
    "#{AVATAR_PALETTE[idx]} #{AVATAR_INK[idx]}"
  end

  # Full class string for the initials circle (keeps the ERB line under erb_lint's max).
  def avatar_initials_circle_classes(user, size = nil)
    [
      avatar_size_class(size),
      avatar_initials_classes(user),
      "grid shrink-0 place-items-center rounded-full font-semibold tabular-nums ring-1 ring-slate-200 select-none"
    ].join(" ")
  end
end
