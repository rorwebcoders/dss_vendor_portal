module ApplicationHelper
  def purchase_order_sort_link(column, label)
    active = @sort_column == column
    next_direction = active && @sort_direction == "asc" ? "desc" : "asc"
    indicator = active ? (@sort_direction == "asc" ? "▲" : "▼") : "↕"

    link_classes = ["purchase-orders-sort-link", ("active" if active)].compact.join(" ")
    link_path = purchase_orders_path(q: @query.presence, status: @status_filter, sort: column, direction: next_direction)

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

  def purchase_order_pagination_pages(current_page, total_pages)
    return (1..total_pages).to_a if total_pages <= 9

    pages = [1, total_pages]
    pages += (current_page - 2..current_page + 2).select { |page| page.between?(1, total_pages) }
    pages += (2..3).to_a if current_page <= 4
    pages += (total_pages - 2..total_pages - 1).to_a if current_page >= total_pages - 3

    pages.uniq.sort.each_with_object([]) do |page, page_items|
      page_items << :gap if page_items.any? && page - page_items.last.to_i > 1
      page_items << page
    end
  end
end
