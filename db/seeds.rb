# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.

admin_email = "admin@example.com"
admin = AdminUser.find_or_initialize_by(email: admin_email)
admin.password = "password"
admin.password_confirmation = "password"
admin.save!

users = [
  { email: "multi.dealer@example.com", password: "password" },
  { email: "single.dealer@example.com", password: "password" },
  { email: "unassigned@example.com", password: "password" }
].index_by { |user| user[:email] }

users.each_value do |attributes|
  user = User.find_or_initialize_by(email: attributes[:email])
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

purchase_orders.each do |attributes|
  PurchaseOrder.find_or_create_by!(po_number: attributes[:po_number]) do |purchase_order|
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

line_items_by_po.each do |po_number, items|
  purchase_order = PurchaseOrder.find_by!(po_number:)
  items.each do |attributes|
    LineItem.find_or_create_by!(purchase_order:, sku: attributes[:sku]) do |line_item|
      line_item.assign_attributes(attributes)
    end.update!(attributes)
  end
end
