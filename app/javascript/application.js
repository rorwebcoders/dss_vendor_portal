// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const themeStorageKey = "dss-vendor-portal-theme"

const storedTheme = () => {
  try {
    return localStorage.getItem(themeStorageKey)
  } catch {
    return null
  }
}

const saveTheme = (theme) => {
  try {
    localStorage.setItem(themeStorageKey, theme)
  } catch {
    // Theme persistence is optional when storage is unavailable.
  }
}

const systemTheme = () => (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")

const preferredTheme = () => storedTheme() || systemTheme()

const currentTheme = () => document.documentElement.getAttribute("data-bs-theme") || preferredTheme()

const setTheme = (theme) => {
  document.documentElement.setAttribute("data-bs-theme", theme)
  saveTheme(theme)
}

const refreshThemeToggle = () => {
  const nextTheme = currentTheme() === "dark" ? "light" : "dark"
  const label = `Switch to ${nextTheme} mode`

  document.querySelectorAll("[data-theme-toggle]").forEach((toggle) => {
    toggle.setAttribute("aria-label", label)
    toggle.setAttribute("title", label)
  })
}

const bindThemeToggles = () => {
  setTheme(preferredTheme())
  refreshThemeToggle()

  document.querySelectorAll("[data-theme-toggle]").forEach((toggle) => {
    if (toggle.dataset.themeToggleBound === "true") return

    toggle.dataset.themeToggleBound = "true"
    toggle.addEventListener("click", () => {
      setTheme(currentTheme() === "dark" ? "light" : "dark")
      refreshThemeToggle()
    })
  })
}

setTheme(preferredTheme())
document.addEventListener("DOMContentLoaded", bindThemeToggles)
document.addEventListener("turbo:load", bindThemeToggles)
