# rails runner db/seeds/import_dealers.rb

# db/seeds/dealers_seed.rb

admin_email = "admin@example.com"
admin = AdminUser.find_or_initialize_by(email: admin_email)
admin.password = "password"
admin.password_confirmation = "password"
admin.save!


require "csv"

csv_file = Rails.root.join("public", "dealers.csv")

def split_address(address)
  return {} if address.blank?

  parts = address.split(",").map(&:strip)

  state_zip = parts[-1].to_s.strip
  state, zip = state_zip.split(" ", 2)

  {
    street: parts[0],
    city: parts[-2],
    state: state,
    zip: zip,
    country: "US"
  }
end

CSV.foreach(csv_file, headers: true) do |row|
  address = split_address(row["Address"])

  dealer = Dealer.find_or_initialize_by(sm_dealer_id: row["Id"])

  dealer.dealer_name              = row["Name"]
  dealer.abbreviation      = row["Abbreviation"]
  dealer.api_name          = row["Api name"]
  dealer.api_location_code = row["Api location code"]
  dealer.email             = "test_kumar@gmail.com"

  dealer.dealer_name       = row["Dealership name"].presence || row["Name"]
  dealer.dealer_address1   = address[:street]
  dealer.dealer_city       = address[:city]
  dealer.dealer_state      = address[:state]
  dealer.dealer_zip        = address[:zip]
  dealer.dealer_country    = address[:country]

  dealer.enabled = ActiveModel::Type::Boolean.new.cast(row["Enabled"])

  dealer.save!
end

puts "Dealers imported: #{Dealer.count}"

# Create test frontend users

multi_dealer_user = User.find_or_create_by!(email: "multi.dealer@example.com") do |u|
  u.password = "Password123!"
  u.password_confirmation = "Password123!"
end

single_dealer_user = User.find_or_create_by!(email: "single.dealer@example.com") do |u|
  u.password = "Password123!"
  u.password_confirmation = "Password123!"
end

# Assign dealers

single_dealer = Dealer.first
multi_dealers = (
  Dealer.limit(2).to_a +
  [Dealer.find_by(sm_dealer_id: 85)]
).compact.uniq

if single_dealer.present?
  single_dealer_user.dealers = [single_dealer]
  single_dealer_user.save!
end

multi_dealer_user.dealers = multi_dealers
multi_dealer_user.save!

puts "Single dealer user assigned dealers: #{single_dealer_user.dealers.count}"
puts "Multi dealer user assigned dealers: #{multi_dealer_user.dealers.count}"
puts "Done"



# require "csv"
# require "securerandom"

# dealer_qty_file = Rails.root.join("public", "dealer_quantities.csv")
# brands_file     = Rails.root.join("public", "brands-5.csv")

# brands_by_sm_id = {}

# CSV.foreach(brands_file, headers: true, col_sep: ";") do |row|
#   brands_by_sm_id[row["id"].to_s] = row["name"]
# end

# po_types = %w[b_order stock_order special_order emergency_order warranty_order]

# rows = []

# CSV.foreach(dealer_qty_file, headers: true, col_sep: ";") do |row|
#   rows << row
# end

# rows.each_slice(5).with_index do |line_rows, index|
#   po_number = "SM-SEED-#{(index + 1).to_s.rjust(6, '0')}"

#   purchase_order = PurchaseOrder.find_or_initialize_by(
#     po_number: po_number
#   )

#   purchase_order.assign_attributes(
#     po_id: 800_000 + index,
#     # po_type: po_types.sample,
#     dealer_response: :pending,
#     status: :pending
#   )

#   purchase_order.save!

#   line_rows.each do |line_row|
#     brand_name = brands_by_sm_id[line_row["brand_id"].to_s] || "Unknown Brand"

#     sku = line_row["sku"].presence || "SKU-#{SecureRandom.hex(4)}"

#     line_item = LineItem.find_or_initialize_by(
#       purchase_order: purchase_order,
#       sku: sku
#     )

#     line_item.assign_attributes(
#       brand: brand_name,
#       title: "SM Product #{SecureRandom.uuid}",
#       quantity: rand(1..10),
#       cost: rand(5.0..500.0).round(2)
#     )

#     line_item.save!
#   end
# end

# puts "Purchase Orders created: #{PurchaseOrder.count}"
# puts "Line Items created: #{LineItem.count}"