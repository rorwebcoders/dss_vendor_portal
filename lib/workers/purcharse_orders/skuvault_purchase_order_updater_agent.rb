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
        status = entry["Status"]
        next if status == "ReadyToShip"
        purchase_order = PurchaseOrder.find_by(
          skuvault_id: skuvault_id
        )
        unless purchase_order
          logger_error("PurchaseOrder not found for Skuvault ID #{skuvault_id}")
          next
        end
        purchase_order.update!(
          skuvault_status: status,
          others_response: entry.to_json
        )
        logger_info(
          "Updated PO #{purchase_order.id} to status #{status}"
        )
      end
      logger_info("Script completed at #{Time.now}")
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
  end

  def get_sales_from_skuvault

    skuvault_tenant_token = Rails.application.credentials[Rails.env.to_sym][:skuvault_tenant_token]
    skuvault_user_token   = Rails.application.credentials[Rails.env.to_sym][:skuvault_user_token]

    skuvault_ids = PurchaseOrder.where(
      status: :non_dropshipping,
      skuvault_status: "ReadyToShip"
    ).where.not(skuvault_id: nil).pluck(:skuvault_id)

    return [] if skuvault_ids.blank?

    all_sales = []

    skuvault_ids.each_slice(10_000) do |batch_ids|
      uri = URI.parse(
        Rails.application.credentials[Rails.env.to_sym][:skuvault_get_sales_api]
      )
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri)
      request['Accept'] = 'application/json'
      request['Content-Type'] = 'application/json'
      request.body = {
        TenantToken: skuvault_tenant_token,
        UserToken: skuvault_user_token,
        OrderIds: batch_ids
      }.to_json
      response = http.request(request)
      logger_info(
        "SkuVault Get Sales Response for #{batch_ids.size} orders: #{response.code}"
      )
      unless response.is_a?(Net::HTTPSuccess)
        logger_error("SkuVault API Error: #{response.code} - #{response.body}")
        next
      end
      body = JSON.parse(response.body)
      all_sales.concat(body["Sales"] || [])
      sleep 10
    end
    all_sales
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