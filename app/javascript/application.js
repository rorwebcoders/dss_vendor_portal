// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const themeStorageKey = "dss-vendor-portal-theme"

const preferredTheme = () => {
  const savedTheme = localStorage.getItem(themeStorageKey)

  if (savedTheme) return savedTheme

  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
}

const setTheme = (theme) => {
  document.documentElement.setAttribute("data-bs-theme", theme)
  localStorage.setItem(themeStorageKey, theme)
}

const refreshThemeToggle = () => {
  const theme = document.documentElement.getAttribute("data-bs-theme") || preferredTheme()

  document.querySelectorAll("[data-theme-toggle]").forEach((toggle) => {
    toggle.textContent = theme === "dark" ? "Light mode" : "Dark mode"
  })
}

const initializeTheme = () => {
  setTheme(preferredTheme())
  refreshThemeToggle()
}

document.addEventListener("turbo:load", () => {
  initializeTheme()

  document.querySelectorAll("[data-theme-toggle]").forEach((toggle) => {
    toggle.addEventListener("click", () => {
      const currentTheme = document.documentElement.getAttribute("data-bs-theme") || "light"
      setTheme(currentTheme === "dark" ? "light" : "dark")
      refreshThemeToggle()
    })
  })
})
