require 'logger'
require 'net/http'
require 'json'
require 'openssl' # Required for SSL options
require 'active_support/all' # Required for time zone operations
class UpdateShipmentIdsForPurchaseOrdersAgent
  attr_accessor :errors

  def initialize
    create_log_file
  end

  def create_log_file
    Dir.mkdir("#{File.dirname(__FILE__)}/logs") unless File.directory?("#{File.dirname(__FILE__)}/logs")
    @logger = Logger.new("#{File.dirname(__FILE__)}/logs/update_shipment_ids_for_purchase_orders_agent.log", 'weekly')
    @logger.formatter = Logger::Formatter.new
  end

  def start_processing
    begin
      logger_info("Script started at #{Time.now}")

      page = 1
      loop do
        shipments = get_shipments_from_shipstation(page)
        logger_info "Processing page #{page} (#{shipments.count} shipments)"
        break if shipments.empty?

        shipments.each do |shipment|
          shipment_id = shipment['shipment_id']
          external_shipment_id = shipment['external_shipment_id']
          shipstation_store_id = shipment["store_id"]
          logger_info("Processing Shipment Id: #{shipment_id}")

          next if external_shipment_id.blank?

          purchase_order = PurchaseOrder.find_by(skuvault_marketplace_id: external_shipment_id)
          next unless purchase_order

          purchase_order.update!(
            shipstation_store_id: shipstation_store_id,
            shipstation_shipment_id: shipment_id
          )
          logger_info("Matched Order #{purchase_order.id} -> Shipment #{shipment_id}")
        end
        page += 1
      end
      
      logger_info("Script completed at #{Time.now}")
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
  end

  def get_shipments_from_shipstation(page)
    url = URI(Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_shipments_api_url])
    params = {
      shipment_status: 'pending',
      page: page,
      page_size: 100
    }
    url.query = URI.encode_www_form(params)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['api-key'] = Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_api_key]
    response = http.request(request)
    result = JSON.parse(response.body)

    shipments = result['shipments'] || []
    return shipments
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
agent = UpdateShipmentIdsForPurchaseOrdersAgent.new
agent.start_processing