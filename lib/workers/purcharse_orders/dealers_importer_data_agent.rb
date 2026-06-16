require 'logger'
require 'net/http'
require 'json'
require 'openssl' # Required for SSL options
require 'active_support/all' # Required for time zone operations
WAREHOUSE_ADDRESS_FIELDS = %w[address_line1 address_line2 address_line3 city_locality state_province postal_code country_code phone ].freeze
class DealersImporterDataAgent
  attr_accessor :errors

  def initialize
    create_log_file
  end

  def create_log_file
    Dir.mkdir("#{File.dirname(__FILE__)}/logs") unless File.directory?("#{File.dirname(__FILE__)}/logs")
    @logger = Logger.new("#{File.dirname(__FILE__)}/logs/dealers_importer_data_agent.log", 'weekly')
    @logger.formatter = Logger::Formatter.new
  end

  def start_processing
    begin
      logger_info("Script started at #{Time.now}")
      dealers = get_dealers_data
      active_ids = []
      dealers.each do |dealer_data|
        begin
          dealer = Dealer.find_or_initialize_by(sm_dealer_id: dealer_data["id"])
          dealer_name = dealer_data["name"]
          logger_info("Processing Dealer: #{dealer_name}")
          dealer.dealer_name = dealer_data["name"]
          dealer.abbreviation = dealer_data["abbreviation"]
          dealer.address_line1 = dealer_data["address_line1"]
          dealer.address_line2 = dealer_data["address_line2"]
          dealer.address_line3 = dealer_data["address_line3"]
          dealer.city_locality = dealer_data["city_locality"]
          dealer.state_province = dealer_data["state_province"]
          dealer.postal_code = dealer_data["postal_code"]
          dealer.country_code = dealer_data["country_code"]
          dealer.phone = dealer_data["phone"]
          dealer.dealership_name = dealer_data["dealership_name"]
          dealer.shipstation_carrier_codes = dealer_data["shipstation_carrier_codes"]
          dealer.enabled = true

          address_changed = WAREHOUSE_ADDRESS_FIELDS.any? do |field|
            dealer.will_save_change_to_attribute?(field)
          end
          if dealer.shipstation_warehouse_id.blank?
            response = create_shipstation_warehouse(dealer_data)
            dealer.shipstation_warehouse_id = response[:warehouse_id] if response[:warehouse_id].present?
            dealer.shipstation_request = response[:request] if response[:request].present?
            dealer.shipstation_response = response[:response] if response[:response].present?
          elsif dealer.shipstation_warehouse_id.present? && address_changed
            dealer_data["warehouse_id"] = dealer.shipstation_warehouse_id
            response = update_shipstation_warehouse(dealer_data)
            dealer.shipstation_request = response[:request] if response[:request].present?
            dealer.shipstation_response = response[:response] if response[:response].present?
          end

          dealer.save
          active_ids << dealer_data["id"]
          logger_info("Stored Dealer: #{dealer_name}")
        rescue StandardError => e
          logger_error(e.message)
          logger_error(e.backtrace.join("\n"))
        end
      end
      Dealer.where.not(sm_dealer_id: active_ids).update_all(enabled: false)
      logger_info("Script completed at #{Time.now}")
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
  end

  def update_shipstation_warehouse(params)
    warehouse_id = params["warehouse_id"]
    url = URI("#{Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_warehouses_api_url]}/#{warehouse_id}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Put.new(url)
    request['Content-Type'] = 'application/json'
    request['api-key'] = Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_api_key]
    request_body = {
      is_default: false,
      name: "Parts Department",
      origin_address: {
        name: "Parts Department",
        company_name: params["dealership_name"],
        phone: params["phone"],
        address_line1: params["address_line1"],
        address_line2: params["address_line2"],
        address_line3: params["address_line3"],
        city_locality: params["city_locality"],
        state_province: params["state_province"],
        postal_code: params["postal_code"],
        country_code: params["country_code"]
      },
      return_address: {
        name: "Parts Department",
        company_name: params["dealership_name"],
        phone: params["phone"],
        address_line1: params["address_line1"],
        address_line2: params["address_line2"],
        address_line3: params["address_line3"],
        city_locality: params["city_locality"],
        state_province: params["state_province"],
        postal_code: params["postal_code"],
        country_code: params["country_code"]
      }
    }
    request.body = request_body.to_json
    response = http.request(request)
    logger_info("Shipstaion Update API Response Code: #{response.code}, Response: #{response.read_body}")

    return { 
      request: "ShipStation Update API Request: #{request_body}",
      response: "Shipstaion Update API Response Code: #{response.code}, Response: #{response.read_body}"
    }
  end

  def create_shipstation_warehouse(params)
    url = URI(Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_warehouses_api_url])
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/json'
    request['api-key'] = Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_api_key]
    request_body = {
      is_default: false,
      name: "Parts Department",
      origin_address: {
        name: "Parts Department",
        company_name: params["dealership_name"],
        phone: params["phone"],
        address_line1: params["address_line1"],
        address_line2: params["address_line2"],
        address_line3: params["address_line3"],
        city_locality: params["city_locality"],
        state_province: params["state_province"],
        postal_code: params["postal_code"],
        country_code: params["country_code"]
      },
      return_address: {
        name: "Parts Department",
        company_name: params["dealership_name"],
        phone: params["phone"],
        address_line1: params["address_line1"],
        address_line2: params["address_line2"],
        address_line3: params["address_line3"],
        city_locality: params["city_locality"],
        state_province: params["state_province"],
        postal_code: params["postal_code"],
        country_code: params["country_code"]
      }
    }
    request.body = request_body.to_json
    response = http.request(request)
    body = response.body
    logger_info("ShipStation Create API Response #{response.code}: #{body}")
    result = JSON.parse(body)

    warehouse_id = result['warehouse_id'] || nil
    return { 
      warehouse_id: warehouse_id,
      request: "ShipStation Create API Request: #{request_body}",
      response: "ShipStation Create API Response #{response.code}: #{body}"
    }
  end

  def get_dealers_data
    dealers_api_url = Rails.application.credentials[Rails.env.to_sym][:dealers_api_url]
    skumonster_api_token = Rails.application.credentials[Rails.env.to_sym][:skumonster_api_token]
    uri = URI(dealers_api_url)
 
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Authorization"] = "Bearer #{skumonster_api_token}"
    request["Content-Type"] = "application/json"
    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "API request failed: #{response.code} - #{response.body}"
    end

    data = JSON.parse(response.body)
     
    logger_info("Status Code: #{response.code}")
    data = JSON.parse(response.body)
    return data['dealers'] || []
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
agent = DealersImporterDataAgent.new
agent.start_processing