#Step 1: Fetches carrier and service codes data from ShipStation.
#Step 2: Process the fetched carrier data and the respective service codes and stores in DB.

require 'logger'
require 'net/http'
require 'json'
require 'openssl' # Required for SSL options
require 'active_support/all' # Required for time zone operations
class CarrierAndServiceCodesImporterAgent
  attr_accessor :errors

  def initialize
    create_log_file
  end

  def create_log_file
    Dir.mkdir("#{File.dirname(__FILE__)}/logs") unless File.directory?("#{File.dirname(__FILE__)}/logs")
    @logger = Logger.new("#{File.dirname(__FILE__)}/logs/carrier_and_service_codes_importer_agent.log", 'weekly')
    @logger.formatter = Logger::Formatter.new
  end

  def start_processing
    begin
      logger_info("Script started at #{Time.now}")

      list_carriers_data = get_carrier_and_service_codes_from_shipstation
      list_carriers_data.each do |carrier_data|
        shipstation_carrier_id = carrier_data["carrier_id"]
        logger_info("Processing Carrier Id: #{shipstation_carrier_id}")

        carrier = Carrier.find_or_initialize_by(shipstation_carrier_id: shipstation_carrier_id)
        carrier.shipstation_carrier_code = carrier_data["carrier_code"]
        carrier.shipstation_account_number = carrier_data["account_number"]
        carrier.shipstation_friendly_name = carrier_data["friendly_name"]
        if carrier.save
          carrier_data["services"].each do |service_data|
            shipstation_service_code = service_data["service_code"]
            logger_info("Processing Service Code: #{shipstation_service_code}")
            service_code = carrier.service_codes.find_or_initialize_by(shipstation_service_code: shipstation_service_code)
            service_code.shipstation_name = service_data["name"]
            service_code.domestic = service_data["domestic"]
            service_code.international = service_data["international"]
            service_code.save
          end
        end
      end
      
      logger_info("Script completed at #{Time.now}")
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
  end

  def get_carrier_and_service_codes_from_shipstation
    url = URI(Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_carriers_api_url])
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['api-key'] = Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_api_key]
    response = http.request(request)
    logger_info("Shipstaion Carrier API Response Code: #{response.code}, Response: #{response.read_body}")
    result = JSON.parse(response.body)
    carriers = result['carriers'] || []
    return carriers
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
agent = CarrierAndServiceCodesImporterAgent.new
agent.start_processing