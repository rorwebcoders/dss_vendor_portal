require 'logger'
require 'net/http'
require 'json'
require 'openssl' # Required for SSL options
require 'active_support/all' # Required for time zone operations
class SkuvaultPurchaseOrderUpdaterAgent
  attr_accessor :errors

  def initialize
    create_log_file
  end

  def create_log_file
    Dir.mkdir("#{File.dirname(__FILE__)}/logs") unless File.directory?("#{File.dirname(__FILE__)}/logs")
    @logger = Logger.new("#{File.dirname(__FILE__)}/logs/skuvault_purchase_order_updater_agent.log", 'weekly')
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
        status = entry["Status"]
        if status != "ReadyToShip"
          purchase_order.skuvault_status = entry["Status"]
          purchase_order.others_response = entry.to_json
          purchase_order.save
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

    skuvault_ids = PurchaseOrder.where(status: :non_dropshipping, skuvault_status: "ReadyToShip").pluck(:skuvault_id)

    uri = URI.parse("#{Rails.application.credentials[Rails.env.to_sym][:skuvault_get_sales_api]}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'

    request.body = {
      "TenantToken" => skuvault_tenant_token,
      "UserToken" => skuvault_user_token,
      "OrderIds" => skuvault_ids
    }.to_json

    response = http.request(request)
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
agent = SkuvaultPurchaseOrderUpdaterAgent.new
agent.start_processing