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
      skuvault_purchase_orders = skuvault_get_pos
      skuvault_purchase_orders = JSON.parse(skuvault_purchase_orders)["PurchaseOrders"] || []
      skuvault_purchase_orders.each do |entry|
        logger_info("Processing PoNumber: #{entry["PoNumber"]}")
        purchase_order = PurchaseOrder.find_or_initialize_by(po_id: entry["PoId"])
        purchase_order.po_number = entry["PoNumber"]
        purchase_order.skuvault_status = entry["Status"]
        purchase_order.payment_status = entry["PaymentStatus"]
        purchase_order.supplier_name = entry["SupplierName"]
        if purchase_order.save!
          entry["LineItems"].each do |skuvault_line_item|
            line_item = purchase_order.line_items.find_or_initialize_by(skuvault_product_id: skuvault_line_item["ProductId"])
            line_item.sku = skuvault_line_item["SKU"]
            line_item.quantity = skuvault_line_item["Quantity"]
            line_item.received_quantity = skuvault_line_item["ReceivedQuantity"]
            line_item.received_date = skuvault_line_item["ReceivedDate"]
            line_item.cost = skuvault_line_item["Cost"]
            line_item.retail_cost = skuvault_line_item["RetailCost"]
            line_item.private_notes = skuvault_line_item["PrivateNotes"]
            line_item.public_notes = skuvault_line_item["PublicNotes"]
            line_item.save!
          end
        end
      end
      
      logger_info("Script completed at #{Time.now}")
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
  end
  
  def skuvault_get_pos
    skuvault_tenant_token = Rails.application.credentials[Rails.env.to_sym][:skuvault_tenant_tokeni_for_import]
    skuvault_user_token = Rails.application.credentials[Rails.env.to_sym][:skuvault_user_token_for_import]
    modified_after_datetime_utc = (Time.zone.now - 24.hours).utc.iso8601(7)
    url = URI("https://app.skuvault.com/api/purchaseorders/getPOs")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = 'application/json'
    request["Accept"] = 'application/json'
    request_body_hash = {
      "IncludeProducts" => "false",
      # "ModifiedAfterDateTimeUtc" => "#{modified_after_datetime_utc}",
      "PageNumber" => 0,
      "Status" => "Everything except Completed",
      "TenantToken" => skuvault_tenant_token,
      "UserToken" => skuvault_user_token
    }

    request.body = request_body_hash.to_json
    response = http.request(request)
    return response.read_body
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