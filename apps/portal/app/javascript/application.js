import "@hotwired/turbo-rails"
import "controllers"
import "chartkick"
import "Chart.js"

function applyChartTheme() {
  const dark = document.documentElement.classList.contains("dark")
  const textColor = dark ? "#94a3b8" : "#64748b"
  const gridColor = dark ? "rgba(148,163,184,0.15)" : "rgba(0,0,0,0.06)"
  const defaults = Chart.defaults

  defaults.color = textColor
  defaults.borderColor = gridColor
  defaults.scales.linear = defaults.scales.linear || {}
  defaults.scales.category = defaults.scales.category || {}

  for (const scaleType of [defaults.scales.linear, defaults.scales.category]) {
    scaleType.ticks = Object.assign(scaleType.ticks || {}, { color: textColor })
    scaleType.grid = Object.assign(scaleType.grid || {}, { color: gridColor })
  }
}

applyChartTheme()
document.addEventListener("theme:changed", applyChartTheme)
