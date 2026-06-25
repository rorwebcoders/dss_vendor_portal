#--------  Get sales data with the status as ReadyToShip from Skuvault using the GetSales API.
#--------  Processes the sales data and stores in PurchaseOrder table.
#-------- The respective LineItem for the PO is stored in the LineItem table refering the PO's id

require 'logger'
require 'net/http'
require 'json'
require 'openssl' # Required for SSL options
require 'active_support/all' # Required for time zone operations
class SkuvaultPurchaseOrderImporterAgent
  attr_accessor :errors

  def initialize
    create_log_file
  end

  def create_log_file
    Dir.mkdir("#{File.dirname(__FILE__)}/logs") unless File.directory?("#{File.dirname(__FILE__)}/logs")
    @logger = Logger.new("#{File.dirname(__FILE__)}/logs/skuvault_purchase_order_importer_agent.log", 'weekly')
    @logger.formatter = Logger::Formatter.new
  end

  def start_processing
    begin
      logger_info("Script started at #{Time.now}")
      skuvault_purchase_orders = get_sales_from_skuvault

      skuvault_purchase_orders.each do |entry|
        skuvault_id = entry["Id"]
        logger_info("Processing Skuvault Id: #{skuvault_id}")

        purchase_order = PurchaseOrder.find_or_initialize_by(skuvault_id: skuvault_id)
        if purchase_order.persisted?
          logger_info("Skuvault Id Already existed: #{skuvault_id}")
          next
        end
        purchase_order.skuvault_marketplace_id = entry["MarketplaceId"]
        purchase_order.skuvault_channel_id = entry["ChannelId"]
        contact_info  = entry["ContactInfo"] || {}
        purchase_order.shipping_firstname = contact_info["FirstName"]
        purchase_order.shipping_lastname = contact_info["LastName"]
        purchase_order.shipping_company = contact_info["Company"]
        purchase_order.shipping_phone = contact_info["Phone"]
        purchase_order.shipping_email = contact_info["Email"]
        shipping_info = entry["ShippingInfo"] || {}
        purchase_order.shipping_address1 = [shipping_info["Address1"], shipping_info["Address2"]].compact.reject(&:blank?).join(", ")
        purchase_order.shipping_city = shipping_info["City"]
        purchase_order.shipping_state = shipping_info["Region"]
        purchase_order.shipping_zip = shipping_info["PostalCode"]
        purchase_order.shipping_country = shipping_info["Country"]
        purchase_order.skuvault_status = entry["Status"]
        purchase_order.read_to_ship_response = entry
        if purchase_order.save!
          entry["SaleItems"].each do |skuvault_line_item|
            line_item = purchase_order.line_items.find_or_create_by!(
              sku: skuvault_line_item["Sku"],
              cost: skuvault_line_item["UnitPrice"]["a"],
              quantity: skuvault_line_item["Quantity"]
            )
          end

          entry["SaleKits"].each do |skuvault_kit_item|
            skuvault_kit_item["KitItems"].each do |sku, component_quantity|
              quantity = component_quantity.to_i * skuvault_kit_item["Quantity"].to_i
              line_item = purchase_order.line_items.find_or_initialize_by(
                sku: sku,
                cost: skuvault_kit_item["UnitPrice"]["a"]
              )
              line_item.quantity = line_item.quantity.to_i + quantity
              line_item.save!
            end
          end
        end
      end
      logger_info("Script completed at #{Time.now}")
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
  end

  def get_sales_from_skuvault
    skuvault_tenant_token = Rails.application.credentials[Rails.env.to_sym][:skuvault_tenant_token]
    skuvault_user_token = Rails.application.credentials[Rails.env.to_sym][:skuvault_user_token]
    uri = URI.parse("#{Rails.application.credentials[Rails.env.to_sym][:skuvault_get_sales_api]}")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Accept"] = "application/json"
    request.body = JSON.dump({
                               "Status" => "ReadyToShip",
                               "TenantToken" => skuvault_tenant_token,
                               "UserToken" => skuvault_user_token
    })
    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    logger_info("Skuvault Get Sales Response: #{response.body}")
    sales_data = JSON.parse(response.body)["Sales"]

    return sales_data
  end

  def logger_info(msg)
    puts msg
    @logger.info msg
  end

  def logger_error(msg)
    puts "Error: #{msg}"
    @logger.error "Error: #{msg}"
  end
end
require File.expand_path('../../../config/environment', __dir__)
agent = SkuvaultPurchaseOrderImporterAgent.new
agent.start_processing
