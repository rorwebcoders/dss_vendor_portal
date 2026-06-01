require "set"

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.

admin_email = "admin@example.com"
admin = AdminUser.find_or_initialize_by(email: admin_email)
admin.password = "password"
admin.password_confirmation = "password"
admin.save!

users = [
  { email: "multi.dealer@example.com", first_name: "Morgan", last_name: "Dealer", password: "password" },
  { email: "single.dealer@example.com", first_name: "Sam", last_name: "Seller", password: "password" },
  { email: "unassigned@example.com", first_name: "Uma", last_name: "Unassigned", password: "password" }
].index_by { |user| user[:email] }

users.each_value do |attributes|
  user = User.find_or_initialize_by(email: attributes[:email])
  user.first_name = attributes[:first_name]
  user.last_name = attributes[:last_name]
  user.password = attributes[:password] if user.new_record?
  user.password_confirmation = attributes[:password] if user.new_record?
  user.save!
end

dealers = [
  {
    name: "Metro Parts Plus DC",
    abbreviation: "MPPDC",
    api_name: "metro_parts_plus",
    api_location_code: "DC01",
    email: "orders@metro.example.com"
  },
  {
    name: "North Valley Auto",
    abbreviation: "NVA",
    api_name: "north_valley_auto",
    api_location_code: "NV02",
    email: "parts@northvalley.example.com"
  },
  {
    name: "South Coast Motors",
    abbreviation: "SCM",
    api_name: "south_coast_motors",
    api_location_code: "SC03",
    email: "po@southcoast.example.com"
  }
]

dealers.each do |attributes|
  Dealer.find_or_create_by!(abbreviation: attributes[:abbreviation]) do |dealer|
    dealer.assign_attributes(attributes.merge(enabled: true))
  end.update!(attributes.merge(enabled: true))
end

multi_dealer_user = User.find_by!(email: "multi.dealer@example.com")
single_dealer_user = User.find_by!(email: "single.dealer@example.com")
metro_dealer = Dealer.find_by!(abbreviation: "MPPDC")
north_dealer = Dealer.find_by!(abbreviation: "NVA")
south_dealer = Dealer.find_by!(abbreviation: "SCM")

[metro_dealer, north_dealer].each do |dealer|
  DealerMembership.find_or_create_by!(dealer:, user: multi_dealer_user)
end
DealerMembership.find_or_create_by!(dealer: south_dealer, user: single_dealer_user)

purchase_orders = [
  { dealer: metro_dealer, po_id: 482450, po_number: "MPPDC-101624-B", po_type: "b_order" },
  { dealer: metro_dealer, po_id: 482451, po_number: "MPPDC-101724-A", po_type: "stock_order" },
  { dealer: north_dealer, po_id: 582450, po_number: "NVA-101824-C", po_type: "b_order" },
  { dealer: south_dealer, po_id: 682450, po_number: "SCM-101924-D", po_type: "special_order" }
]

14.times do |index|
  dealer = index.even? ? metro_dealer : north_dealer
  prefix = dealer.abbreviation
  purchase_orders << {
    dealer:,
    po_id: 700_000 + index,
    po_number: "#{prefix}-20#{(index + 1).to_s.rjust(2, '0')}-SEED",
    po_type: index.even? ? "stock_order" : "b_order"
  }
end

purchase_orders.each do |attributes|
  PurchaseOrder.find_or_create_by!(po_number: attributes[:po_number], status: :pending) do |purchase_order|
    purchase_order.assign_attributes(attributes)
  end.update!(attributes)
end

line_items_by_po = {
  "MPPDC-101624-B" => [
    { sku: "BRK-1001", brand: "Bosch", title: "Front Brake Pad Set", quantity: 4, cost: 42.50 },
    { sku: "FLT-2201", brand: "Mann", title: "Oil Filter", quantity: 12, cost: 8.75 }
  ],
  "MPPDC-101724-A" => [
    { sku: "WPR-3301", brand: "Valeo", title: "Wiper Blade", quantity: 10, cost: 11.25 },
    { sku: "SPK-4401", brand: "NGK", title: "Spark Plug", quantity: 16, cost: 6.10 }
  ],
  "NVA-101824-C" => [
    { sku: "BAT-5501", brand: "Interstate", title: "Battery", quantity: 2, cost: 129.99 },
    { sku: "BEL-6601", brand: "Gates", title: "Serpentine Belt", quantity: 5, cost: 23.40 }
  ],
  "SCM-101924-D" => [
    { sku: "ALT-7701", brand: "Denso", title: "Alternator", quantity: 1, cost: 214.95 },
    { sku: "RAD-8801", brand: "Koyo", title: "Radiator", quantity: 2, cost: 155.30 }
  ]
}

purchase_orders.each do |purchase_order_attributes|
  line_items_by_po[purchase_order_attributes[:po_number]] ||= [
    { sku: "SKU-#{purchase_order_attributes[:po_id]}-A", brand: "DSS", title: "Seeded Service Part", quantity: 2, cost: 19.95 },
    { sku: "SKU-#{purchase_order_attributes[:po_id]}-B", brand: "DSS", title: "Seeded Accessory Part", quantity: 1, cost: 34.50 }
  ]
end

line_items_by_po.each do |po_number, items|
  purchase_order = PurchaseOrder.find_by!(po_number:)
  items.each do |attributes|
    LineItem.find_or_create_by!(purchase_order:, sku: attributes[:sku]) do |line_item|
      line_item.assign_attributes(attributes)
    end.update!(attributes)
  end
end

performance_po_count = ENV.fetch("SEED_PERFORMANCE_PO_COUNT", 50_000).to_i
performance_po_dealers = [metro_dealer, north_dealer, south_dealer]
performance_po_types = %w[b_order stock_order special_order emergency_order warranty_order]
performance_po_responses = PurchaseOrder.dealer_responses.keys
performance_po_prefix = "PERF"
existing_performance_po_numbers = PurchaseOrder.where("po_number LIKE ?", "#{performance_po_prefix}-%").pluck(:po_number).to_set
now = Time.current
performance_purchase_orders = []

performance_po_count.times do |index|
  sequence = index + 1
  po_number = "#{performance_po_prefix}-#{sequence.to_s.rjust(5, '0')}"
  next if existing_performance_po_numbers.include?(po_number)

  dealer = performance_po_dealers[index % performance_po_dealers.size]

  performance_purchase_orders << {
    dealer_id: dealer.id,
    po_id: 900_000 + sequence,
    po_number:,
    po_type: performance_po_types[index % performance_po_types.size],
    dealer_response: performance_po_responses[index % performance_po_responses.size],
    created_at: now - index.minutes,
    updated_at: now
  }
end

performance_purchase_orders.each_slice(1_000) do |batch|
  PurchaseOrder.insert_all(batch)
end

Dealer.all.each_with_index do |dealer, index|
  dealer.dealer_address1 = "1 Market St"
  dealer.dealer_city = "San Francisco"
  dealer.dealer_state = "CA"
  dealer.dealer_zip = "94105"
  dealer.dealer_country = "US"
  dealer.sm_dealer_id = index + 1
  dealer.save
end

puts "Seeded #{performance_po_count} performance purchase order combinations (#{performance_purchase_orders.size} inserted)."
