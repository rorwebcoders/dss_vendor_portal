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
  const theme = currentTheme()
  const nextTheme = theme === "dark" ? "light" : "dark"
  const label = `Switch to ${nextTheme} mode`

  document.querySelectorAll("[data-theme-toggle]").forEach((toggle) => {
    toggle.setAttribute("aria-label", label)
    toggle.setAttribute("title", label)

    const sunIcon = toggle.querySelector('[data-theme-icon="sun"]')
    const moonIcon = toggle.querySelector('[data-theme-icon="moon"]')

    if (sunIcon) sunIcon.hidden = theme !== "dark"
    if (moonIcon) moonIcon.hidden = theme === "dark"
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

const sidebarStorageKey = "dss-vendor-portal-sidebar-collapsed"
const desktopSidebarQuery = window.matchMedia("(min-width: 992px)")

const sidebarStoredCollapsed = () => {
  try {
    return localStorage.getItem(sidebarStorageKey) === "true"
  } catch {
    return false
  }
}

const saveSidebarCollapsed = (collapsed) => {
  try {
    localStorage.setItem(sidebarStorageKey, collapsed ? "true" : "false")
  } catch {
    // Sidebar persistence is optional when storage is unavailable.
  }
}

const setSidebarExpandedAttribute = () => {
  const expanded = desktopSidebarQuery.matches ? !document.body.classList.contains("dealer-sidebar-collapsed") : document.body.classList.contains("dealer-sidebar-open")

  document.querySelectorAll("[data-sidebar-toggle]").forEach((toggle) => {
    toggle.setAttribute("aria-expanded", expanded ? "true" : "false")
  })
}

const closeDealerSidebar = () => {
  document.body.classList.remove("dealer-sidebar-open")
  setSidebarExpandedAttribute()
}

const toggleDealerSidebar = () => {
  if (desktopSidebarQuery.matches) {
    const collapsed = !document.body.classList.contains("dealer-sidebar-collapsed")
    document.body.classList.toggle("dealer-sidebar-collapsed", collapsed)
    saveSidebarCollapsed(collapsed)
    closeDealerSidebar()
  } else {
    document.body.classList.toggle("dealer-sidebar-open")
    setSidebarExpandedAttribute()
  }
}

const bindDealerSidebar = () => {
  if (!document.querySelector("[data-dealer-layout]")) return

  document.body.classList.toggle("dealer-sidebar-collapsed", desktopSidebarQuery.matches && sidebarStoredCollapsed())
  if (desktopSidebarQuery.matches) closeDealerSidebar()
  setSidebarExpandedAttribute()

  document.querySelectorAll("[data-sidebar-toggle]").forEach((toggle) => {
    if (toggle.dataset.sidebarToggleBound === "true") return

    toggle.dataset.sidebarToggleBound = "true"
    toggle.addEventListener("click", toggleDealerSidebar)
  })

  document.querySelectorAll("[data-sidebar-close]").forEach((closeButton) => {
    if (closeButton.dataset.sidebarCloseBound === "true") return

    closeButton.dataset.sidebarCloseBound = "true"
    closeButton.addEventListener("click", closeDealerSidebar)
  })

  document.querySelectorAll(".dealer-side-nav-link").forEach((link) => {
    if (link.dataset.sidebarLinkBound === "true") return

    link.dataset.sidebarLinkBound = "true"
    link.addEventListener("click", () => {
      if (!desktopSidebarQuery.matches) closeDealerSidebar()
    })
  })
}

const handleDealerSidebarKeydown = (event) => {
  if (event.key === "Escape") closeDealerSidebar()
}

window.addEventListener("resize", bindDealerSidebar)
desktopSidebarQuery.addEventListener("change", bindDealerSidebar)
document.addEventListener("keydown", handleDealerSidebarKeydown)
document.addEventListener("DOMContentLoaded", bindDealerSidebar)
document.addEventListener("turbo:load", bindDealerSidebar)
