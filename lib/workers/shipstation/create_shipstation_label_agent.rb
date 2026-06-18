require 'logger'
require 'net/http'
require 'json'
require 'openssl' # Required for SSL options
require 'active_support/all' # Required for time zone operations
class CreateShipstationLabelAgent
  attr_accessor :errors

  def initialize
    create_log_file
  end

  def create_log_file
    Dir.mkdir("#{File.dirname(__FILE__)}/logs") unless File.directory?("#{File.dirname(__FILE__)}/logs")
    @logger = Logger.new("#{File.dirname(__FILE__)}/logs/create_shipstation_label_agent.log", 'weekly')
    @logger.formatter = Logger::Formatter.new
  end

  def start_processing
    begin
      logger_info("Script started at #{Time.now}")

      purchase_orders_data = PurchaseOrder.where.not(shipstation_shipment_id: [nil, ''], dealer_response: :accepted)
      purchase_orders_data.each do |purchase_order|
        begin
          logger_info("Processing PurchaseOrder Id: #{purchase_order.id}")
          shipstation_shipment_id = purchase_order.shipstation_shipment_id

          response = update_shipment_in_shipstation(purchase_order)
          if response
            dealer = purchase_order.dealer
            if dealer.shipstation_service_codes.is_a?(Array) && dealer.shipstation_service_codes.present?
              sm_service_code_records = dealer.shipstation_service_codes
              service_code_records = ServiceCode.where(
                shipstation_service_code: sm_service_code_records
              )
              service_codes = service_code_records.pluck(:shipstation_service_code)
              carrier_ids = Carrier.where(id: service_code_records.select(:carrier_id)).pluck(:shipstation_carrier_id)
            elsif dealer.service_codes.present?
              service_codes = dealer.service_codes.pluck(:shipstation_service_code)
              carrier_ids = dealer.carriers.pluck(:shipstation_carrier_id)
            else
              service_code_records = ServiceCode.where(is_global: true)
              service_codes = service_code_records.pluck(:shipstation_service_code)
              carrier_ids = Carrier.where(id: service_code_records.select(:carrier_id)).pluck(:shipstation_carrier_id)
            end
            request_body = {
              shipment_id: shipstation_shipment_id,
              rate_options: {
                carrier_ids: carrier_ids.compact.uniq,
                package_types: ['package'],
                service_codes: service_codes.compact.uniq,
                calculate_tax_amount: false,
                preferred_currency: 'USD',
                is_return: false
              }
            }
            rate_id, min_amount = get_shipping_rate_from_shipstation(request_body)
            if rate_id.present?
              tracking_number, tracking_url = create_shipstation_label(rate_id)
              purchase_order.update!(
                tracking_number: tracking_number,
                shipstation_label_url: tracking_url,
                status: :label_created
              )
            end
          end
        rescue StandardError => e
          logger_error(e.message)
          logger_error(e.backtrace.join("\n"))
        end
      end
      logger_info("Script completed at #{Time.now}")
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
  end

  def create_shipstation_label(rate_id)
    if Rails.env.development?
      tracking_number = "Test-782758401696"
      tracking_url = "https://www.fedex.com/fedextrack/?action=track&trackingnumber=1234"
      return tracking_number, tracking_url
    else
      url = URI('https://api.shipstation.com/v2/labels/rates/' + rate_id)
    end
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/json'
    request['api-key'] = Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_api_key]
    request.body = {
      validate_address: 'no_validation',
      label_layout: '4x6',
      label_format: 'pdf',
      label_download_type: 'url',
      display_scheme: 'label'
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    tracking_number = result["tracking_number"]
    tracking_url = result["tracking_url"]
    return tracking_number, tracking_url
  end

  def update_shipment_in_shipstation(purchase_order)
    shipstation_shipment_id = purchase_order.shipstation_shipment_id
    url = URI("#{Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_shipments_api_url]}/#{shipstation_shipment_id}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Put.new(url)
    request['Content-Type'] = 'application/json'
    request['api-key'] = Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_api_key]

    request.body = {
      store_id: purchase_order.shipstation_store_id,
      external_shipment_id: purchase_order.skuvault_marketplace_id,
      shipment_number: purchase_order.po_number,
      ship_to: {
        name: [purchase_order.shipping_firstname, purchase_order.shipping_lastname].compact.join(' '),
        phone: purchase_order.shipping_phone,
        email: purchase_order.shipping_email,
        company_name: purchase_order.shipping_company,
        address_line1: purchase_order.shipping_address1,
        address_line2: '',
        address_line3: '',
        city_locality: purchase_order.shipping_city,
        state_province: purchase_order.shipping_state,
        postal_code: purchase_order.shipping_zip,
        country_code: purchase_order.shipping_country,
        address_residential_indicator: 'yes'
      },
      ship_from: {
        name: "Parts Department",
        phone: purchase_order.dealer.phone,
        email: '',
        company_name: purchase_order.dealer.dealership_name,
        address_line1: purchase_order.dealer.address_line1,
        address_line2: purchase_order.dealer.address_line2,
        address_line3: purchase_order.dealer.address_line3,
        city_locality: purchase_order.dealer.city_locality,
        state_province: purchase_order.dealer.state_province,
        postal_code: purchase_order.dealer.postal_code,
        country_code: purchase_order.dealer.country_code,
        address_residential_indicator: 'yes'
      },
      warehouse_id: purchase_order.dealer.shipstation_warehouse_id,
      return_to: {
        name: "Parts Department",
        phone: purchase_order.dealer.phone,
        email: '',
        company_name: purchase_order.dealer.dealership_name,
        address_line1: purchase_order.dealer.address_line1,
        address_line2: purchase_order.dealer.address_line2,
        address_line3: purchase_order.dealer.address_line3,
        city_locality: purchase_order.dealer.city_locality,
        state_province: purchase_order.dealer.state_province,
        postal_code: purchase_order.dealer.postal_code,
        country_code: purchase_order.dealer.country_code,
        address_residential_indicator: 'yes'
      },
      packages: [
        {
          package_id: purchase_order.po_number.to_s,
          package_code: 'package',
          package_name: 'package',
          weight: {
            value: purchase_order.weight,
            unit: purchase_order.units
          },
          dimensions: {
            unit: 'inch',
            length: purchase_order.length,
            width: purchase_order.width,
            height: purchase_order.height
          },
          insured_value: {
            currency: 'usd',
            amount: 0
          },
          label_messages: {
            reference1: '',
            reference2: '',
            reference3: ''
          },
          external_package_id: '',
          content_description: '',
          products: []
        }
      ]
    }.to_json
    response = http.request(request)
    result = JSON.parse(response.body)
    logger_info("Shipstaion Shipment Update API Response Code: #{response.code}, Response: #{response.read_body}")
    return result["errors"].empty? ? true : false
  end

  def get_shipping_rate_from_shipstation(body)
    url = URI(Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_get_rates_api_url])
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/json'
    request['api-key'] = Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_api_key]
    request.body = body.to_json
    response = http.request(request)
    logger_info("Shipstaion Shipping Rate API Response Code: #{response.code}, Response: #{response.read_body}")
    result = JSON.parse(response.body)
    cheapest_rate = result["rate_response"]["rates"].min_by { |rate| rate["shipping_amount"]["amount"] }
    rate_id = cheapest_rate["rate_id"]
    min_amount = cheapest_rate["shipping_amount"]["amount"]
    return rate_id, min_amount
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
agent = CreateShipstationLabelAgent.new
agent.start_processing