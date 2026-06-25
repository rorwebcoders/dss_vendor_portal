require 'logger'
require 'net/http'
require 'json'
class CreateShipstationLabelJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 1.minute, attempts: 5
  
  def perform(purchase_order_id)
    purchase_order = PurchaseOrder.find_by(id: purchase_order_id)
    return unless purchase_order
    # return if purchase_order.label_created_status?

    begin
      shipstation_shipment_id = purchase_order.shipstation_shipment_id
      
      return if shipstation_shipment_id.blank?

      get_shipment_response = get_shipment_from_shipstation(shipstation_shipment_id)

      response = update_shipment_in_shipstation(get_shipment_response, purchase_order)
      if response
        dealer = purchase_order.dealer
        if dealer.shipstation_service_codes.is_a?(Array) && dealer.shipstation_service_codes.present?
          sm_service_code_records = dealer.shipstation_service_codes
          service_code_records = ServiceCode.where(
            shipstation_service_code: sm_service_code_records, enabled: true
          )
          service_codes = service_code_records.pluck(:shipstation_service_code)
          carrier_ids = Carrier.where(id: service_code_records.select(:carrier_id), enabled: true).pluck(:shipstation_carrier_id)
        else
          service_code_records = ServiceCode.where(enabled: true)
          service_codes = service_code_records.pluck(:shipstation_service_code)
          carrier_ids = Carrier.where(id: service_code_records.select(:carrier_id), enabled: true).pluck(:shipstation_carrier_id)
        end
        request_body = { 
          shipment_id: shipstation_shipment_id,
          carrier_ids: carrier_ids.compact.uniq,
          service_codes: service_codes.compact.uniq
        }
        rate_id, min_amount = get_shipping_rate_from_shipstation(request_body)
        if rate_id.present?
          tracking_number, tracking_url, label_pdf_url = create_shipstation_label(rate_id)
          purchase_order.update!(
            tracking_number: tracking_number,
            shipstation_label_url: tracking_url,
            shipstation_label_pdf_url: label_pdf_url,
            status: :label_created
          )
        end
      end
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
  end

  def get_shipment_from_shipstation(shipment_id)
    url = URI("#{Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_shipments_api_url]}/#{shipment_id}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['api-key'] = Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_api_key]
    response = http.request(request)
    body = response.body
    result = JSON.parse(body)
    logger_info("Get Shipment API Response Code: #{response.code}, Response: #{body}")
    return result
  end

  def create_shipstation_label(rate_id)
    if Rails.env.development?
      tracking_number = "Test-782758401696"
      tracking_url = "https://www.fedex.com/fedextrack/?action=track&trackingnumber=1234"
      label_pdf_url = "https://api.shipstation.com/v2/downloads/6/p5OJGi7mmkuTDWxWS3gPIw/label-919147992.pdf"
      return tracking_number, tracking_url
    else
      url = URI("#{Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_create_shipstation_label_api_url]}/#{rate_id}")
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
    label_pdf_url = result['label_download']["pdf"]
    return tracking_number, tracking_url
  end

  def update_shipment_in_shipstation(get_shipment_params, purchase_order)
    shipstation_shipment_id = purchase_order.shipstation_shipment_id
    url = URI("#{Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_shipments_api_url]}/#{shipstation_shipment_id}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Put.new(url)
    request['Content-Type'] = 'application/json'
    request['api-key'] = Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_api_key]

    get_shipment_params["warehouse_id"] = purchase_order.dealer.shipstation_warehouse_id
    ship_to = get_shipment_params["ship_to"]
    ship_to["name"] = [purchase_order.shipping_firstname, purchase_order.shipping_lastname].compact.join(' ')
    ship_to["phone"] = purchase_order.shipping_phone
    ship_to["email"] = purchase_order.shipping_email
    ship_to["company_name"] = purchase_order.shipping_company
    ship_to["address_line1"] = purchase_order.shipping_address1
    ship_to["city_locality"] = purchase_order.shipping_city
    ship_to["state_province"] = purchase_order.shipping_state
    ship_to["postal_code"] = purchase_order.shipping_zip
    ship_to["country_code"] = purchase_order.shipping_country

    ship_from = get_shipment_params["ship_from"]
    ship_from["name"] = purchase_order.dealer.dealer_name
    ship_from["phone"] = purchase_order.dealer.phone
    ship_from["company_name"] = purchase_order.dealer.dealership_name
    ship_from["address_line1"] = purchase_order.dealer.address_line1
    ship_from["address_line2"] = purchase_order.dealer.address_line2
    ship_from["address_line3"] = purchase_order.dealer.address_line3
    ship_from["city_locality"] = purchase_order.dealer.city_locality
    ship_from["state_province"] = purchase_order.dealer.state_province
    ship_from["postal_code"] = purchase_order.dealer.postal_code
    ship_from["country_code"] = purchase_order.dealer.country_code

    return_to = get_shipment_params["return_to"]
    return_to["name"] = Rails.application.credentials[Rails.env.to_sym][:shipstation_return_address_name]
    return_to["phone"] = Rails.application.credentials[Rails.env.to_sym][:shipstation_return_address_phone]
    return_to["company_name"] = Rails.application.credentials[Rails.env.to_sym][:shipstation_return_address_company_name]
    return_to["address_line1"] = Rails.application.credentials[Rails.env.to_sym][:shipstation_return_address_address_line1]
    return_to["address_line2"] = Rails.application.credentials[Rails.env.to_sym][:shipstation_return_address_address_line2]
    return_to["address_line3"] = Rails.application.credentials[Rails.env.to_sym][:shipstation_return_address_address_line3]
    return_to["city_locality"] = Rails.application.credentials[Rails.env.to_sym][:shipstation_return_address_city_locality]
    return_to["state_province"] = Rails.application.credentials[Rails.env.to_sym][:shipstation_return_address_state_province]
    return_to["postal_code"] = Rails.application.credentials[Rails.env.to_sym][:shipstation_return_address_postal_code]
    return_to["country_code"] = Rails.application.credentials[Rails.env.to_sym][:shipstation_return_address_country_code]

    packages = get_shipment_params["packages"].first
    packages["package_id"] = purchase_order.po_number.to_s
    packages["package_code"] = 'package'
    packages["package_name"] = 'package'
    packages["weight"]["value"] = purchase_order.weight
    packages["weight"]["unit"] = purchase_order.units

    packages["dimensions"]["unit"] = 'inch'
    packages["dimensions"]["length"] = purchase_order.length
    packages["dimensions"]["width"] = purchase_order.width
    packages["dimensions"]["height"] = purchase_order.height

    request.body = get_shipment_params.to_json
    response = http.request(request)
    body = response.body
    result = JSON.parse(body)
    logger_info("Shipstaion Shipment Update API Response Code: #{response.code}, Response: #{body}")
    return result["errors"].empty? ? true : false
  end

  def get_shipping_rate_from_shipstation(params)
    url = URI(Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_get_rates_api_url])
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/json'
    request['api-key'] = Rails.application.credentials[Rails.env.to_sym][:shipstation_v2_api_key]
    request.body = {
      shipment_id: params[:shipment_id],
      rate_options: {
        carrier_ids: params[:carrier_ids],
        package_types: ['package'],
        service_codes: params[:service_codes],
        calculate_tax_amount: false,
        preferred_currency: 'USD',
        is_return: false
      }
    }.to_json
    response = http.request(request)
    body = response.body
    result = JSON.parse(body.force_encoding('UTF-8'))
    logger_info("Shipstaion Shipping Rate API Response Code: #{response.code}, Response: #{result}")
      
    rates = result["rate_response"]["rates"] || []
    return [nil, nil] if rates.empty?

    cheapest_rate = rates.min_by { |rate| rate["shipping_amount"]["amount"] }
    rate_id = cheapest_rate["rate_id"]
    min_amount = cheapest_rate["shipping_amount"]["amount"]
    return rate_id, min_amount
  end

  def logger_info(msg)
    puts msg
    Rails.logger.info msg
  end

  def logger_error(msg)
    puts "Error: #{msg}"
    Rails.logger.error "Error: #{msg}"
  end
end