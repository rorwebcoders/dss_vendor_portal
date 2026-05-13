require 'logger'
require 'net/http'
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

      purchase_orders = PurchaseOrder.where(status: :pending)
      purchase_orders_data = purchase_orders.map do |purchase_order|
        sku_quantities = purchase_order.line_items.each_with_object(Hash.new(0)) do |line_item, hash|
          hash[line_item.sku] += line_item.quantity.to_i
        end

        {
          purchase_order: purchase_order,
          po_number: purchase_order.po_number,
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
        logger_info("Processing PoNumber: #{po_data[:po_number]}")

        purchase_order = po_data[:purchase_order]
        line_items = po_data[:line_items]

        # reserved_response = fetch_reserved_quantity_from_skumonster(line_items)
        reserved_response = {
          "reserved_quantity": {
            "12345": 0,
            "1234": 0
          },
          "dealers": [
            {
             "id": 99,
             "priority_position": 15
            },
            {
             "id": 128,
             "priority_position": 10
            }
          ]
        }

        reserved_quantities = reserved_response[:reserved_quantity]
        ascending_dealers = reserved_response[:dealers].sort_by { |d| d[:priority_position] }

        dropshipping = false
        ascending_dealers.each do |dealer|
          dealer_id = dealer[:id]

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
            }.to_json

            # notify_orders_to_skumonster(notify_dealer_request_body)

            purchase_order.update(status: :dropshipping)
            dropshipping = true
            break
          end
        end

        logger_info("Finished PoNumber: #{po_data[:po_number]}, #{dropshipping == true ? "Eligible" : "Not Eligible"} for dropshipping")
        unless dropshipping
          purchase_order.update(status: :non_dropshipping)
        end
      end

      logger_info("Script completed at #{Time.now}")
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
  end

  def notify_orders_to_skumonster(notify_request)
    notify_orders_api_url = Rails.env.development? ? 'http://localhost:3000/'
                                : 'https://sm.dealersalessolutions.com/notify_orders'

    url = URI.parse(notify_orders_api_url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    token = Rails.application.credentials[Rails.env.to_sym][:skumonster_api_token]
    request = Net::HTTP::Post.new(url.path, {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{token}"
    })

    # Request:
    # {
    #   "dealer_id": 100,
    #   "line_items": [
    #     {
    #       "sku": "12345",
    #       "quantity": 20
    #     },
    #     {
    #       "sku": "67890",
    #       "quantity": 1
    #     }
    #   ]
    # }
    request_body = notify_request
    request.body = request_body
    response = http.request(request)

    return response.body
  end
  
  def fetch_reserved_quantity_from_skumonster(line_items)
    reserved_quantity_api_url = Rails.env.development? ? 'http://localhost:3000/'
                                : 'https://sm.dealersalessolutions.com/fetch_reserved_quantity'

    url = URI.parse(reserved_quantity_api_url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    token = Rails.application.credentials[Rails.env.to_sym][:skumonster_api_token]
    request = Net::HTTP::Post.new(url.path, {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{token}"
    })
    
    # Sample Request:
    # {
    #   "line_items": [
    #     {
    #       "sku": "12345",
    #       "quantity": 2
    #     },
    #     {
    #       "sku": "67890",
    #       "quantity": 1
    #     }
    #   ]
    # }

    request_body = { line_items: line_items }.to_json
    request.body = request_body
    response = http.request(request)

    # Response Sample:
    # response = {
    #   "reserved_quantity": {
    #     "sku12345": 5,
    #     "67890": 0
    #   },
    #   "dealers": [
    #     {
    #      "id": 99,
    #      "priority_position": 5
    #     },
    #     {
    #      "id": 128,
    #      "priority_position": 10
    #     }
    #   ]
    # }

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