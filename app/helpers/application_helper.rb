module ApplicationHelper
  def purchase_order_sort_link(column, label)
    active = @sort_column == column
    next_direction = active && @sort_direction == "asc" ? "desc" : "asc"
    indicator = active ? (@sort_direction == "asc" ? "▲" : "▼") : "↕"

    link_classes = ["purchase-orders-sort-link", ("active" if active)].compact.join(" ")
    link_path = purchase_orders_path(q: @query.presence, sort: column, direction: next_direction)

    link_to link_path, class: link_classes do
      safe_join(
        [content_tag(:span, label), content_tag(:span, indicator, class: "purchase-orders-sort-indicator")],
        " "
      )
    end
  end

  def purchase_order_status_badge_class(status)
    ["purchase-order-status", "purchase-order-status--#{status.presence || "unknown"}"].join(" ")
  end
end
