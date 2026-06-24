require 'logger'
require 'net/http'
require 'uri'
require 'json'
require 'openssl' # Required for SSL options
require 'active_support/all' # Required for time zone operations
class PurchaseOrderProcessorAgent
  attr_accessor :errors

  def initialize
    create_log_file
  end

  def create_log_file
    Dir.mkdir("#{File.dirname(__FILE__)}/logs") unless File.directory?("#{File.dirname(__FILE__)}/logs")
    @logger = Logger.new("#{File.dirname(__FILE__)}/logs/purchase_order_processor_agent.log", 'weekly')
    @logger.formatter = Logger::Formatter.new
  end

  def start_processing
    begin
      logger_info("Script started at #{Time.now}")

      sync_shipstation_shipments # Import and update shipstation_shipment_id from ShipStation

      purchase_orders = PurchaseOrder.where.not(shipstation_shipment_id: [nil, '']).where(status: :pending)
      dealer_data = Dealer.pluck(:id, :sm_dealer_id, :abbreviation).to_h do |id, sm_dealer_id, abbreviation|
                     [sm_dealer_id, { our_dealer_id: id, abbreviation: abbreviation }]
                   end
      purchase_orders_data = purchase_orders.map do |purchase_order|
        sku_quantities = purchase_order.line_items.each_with_object(Hash.new(0)) do |line_item, hash|
          hash[line_item.sku] += line_item.quantity.to_i
        end
        {
          purchase_order: purchase_order,
          id: purchase_order.id,
          total_quantity: sku_quantities.values.sum,
          line_items: sku_quantities.map do |sku, quantity|
            {
              sku: sku,
              quantity: quantity
            }
          end
        }
      end
      purchase_orders_data = purchase_orders_data.sort_by do |po|
        -po[:total_quantity]
      end

      pending_quantities_by_sku = Hash.new(0)
      purchase_orders.each do |po|
        po.line_items.each do |li|
          pending_quantities_by_sku[li.sku] += li.quantity.to_i
        end
      end

      notify_dealers_data = {}
      purchase_orders_data.each do |po_data|
        begin
          logger_info("Processing Po Id: #{po_data[:id]}")

          purchase_order = po_data[:purchase_order]
          line_items = po_data[:line_items]

          reserved_response = fetch_reserved_quantity_from_skumonster(line_items)
          reserved_response = JSON.parse(reserved_response)
          reserved_quantities = reserved_response["reserved_quantity"]
          ascending_dealers = reserved_response["dealers"].sort_by { |d| d["priority_position"] }

          dropshipping = false
          ascending_dealers.each do |dealer|
            dealer_id = dealer["id"]

            eligible = true
            notify_dealers_data[dealer_id] ||= {}
            line_items.each do |li|
              sku = li[:sku]
              line_item_quantity = li[:quantity]

              reserved_qty = reserved_quantities[sku.to_sym].to_i
              pending_qty = pending_quantities_by_sku[sku]
              allocated_qty = notify_dealers_data[dealer_id][sku].to_i

              order_quantity = (pending_qty - reserved_qty) - allocated_qty
              if order_quantity >= line_item_quantity
                next
              else
                eligible = false
                break
              end
            end

            if eligible
              line_items.each do |li|
                sku = li[:sku]
                line_item_quantity = li[:quantity]

                notify_dealers_data[dealer_id][sku] ||= 0
                notify_dealers_data[dealer_id][sku] += line_item_quantity
              end

              notify_dealer_request_body = {
                dealer_id: dealer_id,
                line_items: line_items
              }

              notify_orders_to_skumonster(notify_dealer_request_body)

              dealer = dealer_data[dealer_id.to_i]
              our_dealer_id = dealer[:our_dealer_id]
              abbreviation = dealer[:abbreviation]
              po_number = "#{abbreviation}-#{Time.current.strftime('%d%m%y-%H%M%S-%3N')}"
              purchase_order.update(po_number: po_number, dealer_assigned_at: Time.zone.now, dealer_id: our_dealer_id, status: :dropshipping, notified_sm_request: notify_dealer_request_body)
              dropshipping = true
              break
            end
          end

          logger_info("Finished Po Id: #{po_data[:id]}, #{dropshipping == true ? "Eligible" : "Not Eligible"} for dropshipping")
          unless dropshipping
            purchase_order.update(status: :non_dropshipping)
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

  def sync_shipstation_shipments
    begin
      page = 1
      loop do
        shipments = get_shipments_from_shipstation(page)
        logger_info "Processing page #{page} (#{shipments.count} shipments)"
        break if shipments.empty?

        shipments.each do |shipment|
          shipment_id = shipment['shipment_id']
          shipment_number = shipment['shipment_number']
          shipstation_store_id = shipment["store_id"]
          next if shipment_number.blank?
          logger_info("Processing Shipment Id: #{shipment_id}, ShipmentNumber: #{shipment_number}")

          purchase_order = PurchaseOrder.find_by(skuvault_marketplace_id: shipment_number)
          next unless purchase_order

          purchase_order.update!(
            shipstation_store_id: shipstation_store_id,
            shipstation_shipment_id: shipment_id
          )
          logger_info("Matched Order #{purchase_order.id} -> Shipment #{shipment_id}")
        end
        page += 1
      end
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

  def notify_orders_to_skumonster(notify_request)
    notify_orders_api_url = Rails.application.credentials[Rails.env.to_sym][:notify_orders_api_url]
    skumonster_api_token = Rails.application.credentials[Rails.env.to_sym][:skumonster_api_token]
    uri = URI(notify_orders_api_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Authorization"] = skumonster_api_token
    request["Content-Type"] = "application/json"
    request_body = notify_request.to_json
    request.body = request_body
    response = http.request(request)
    logger_info("Notify Orders Response: #{response.body}")
   
    return response.body
  end
  
  def fetch_reserved_quantity_from_skumonster(line_items)
    reserved_quantity_api_url = Rails.application.credentials[Rails.env.to_sym][:reserved_quantity_api_url]
    skumonster_api_token = Rails.application.credentials[Rails.env.to_sym][:skumonster_api_token]
    uri = URI(reserved_quantity_api_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Authorization"] = skumonster_api_token
    request["Content-Type"] = "application/json"
    request_body = { line_items: line_items }.to_json
    request.body = request_body
    response = http.request(request)
    logger_info("Reserved Quantity Response: #{response.body}")

    return response.body
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
agent = PurchaseOrderProcessorAgent.new
agent.start_processing