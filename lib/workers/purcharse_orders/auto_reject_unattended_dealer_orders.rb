# The script fetches POs that are in Pending status.
# It checks whether a PO assigned to a dealer has exceeded 24 hours.
# If the assigned time exceeds 24 hours, the script automatically rejects the PO for that dealer,
# allowing it to be reassigned to a different dealer when the PO is processed again.

require 'logger'
require 'net/http'
require 'uri'
require 'json'
require 'openssl' # Required for SSL options
require 'active_support/all' # Required for time zone operations
class AutoRejectUnattendedDealerOrders
  attr_accessor :errors

  def initialize
    create_log_file
  end

  def create_log_file
    Dir.mkdir("#{File.dirname(__FILE__)}/logs") unless File.directory?("#{File.dirname(__FILE__)}/logs")
    @logger = Logger.new("#{File.dirname(__FILE__)}/logs/auto_reject_unattended_dealer_orders.log", 'weekly')
    @logger.formatter = Logger::Formatter.new
  end

  def start_processing
    begin
      logger_info("Script started at #{Time.now}")

      purchase_orders = PurchaseOrder.where(status: :pending).where.not(dealer_id: nil)
      purchase_orders.find_each do |purchase_order|
        logger_info("Processing Po Id: #{purchase_order.id}")
        dealer_assigned_at = purchase_order.dealer_assigned_at
        next if dealer_assigned_at.blank?
        if dealer_assigned_at <= 24.hours.ago
          next unless purchase_order.pending_dealer_response?

          RejectedOrder.create!(
            purchase_order_id: purchase_order.id,
            dealer_id: purchase_order.dealer_id,
            po_number: purchase_order.po_number,
            rejected_at: Time.current,
            purchase_order_data: purchase_order.as_json.to_json,
            line_items_data: purchase_order.line_items.as_json.to_json,
            status: :rejected
          )
          purchase_order.update!(dealer_response: nil, dealer: nil, po_number: nil, status: :pending)
          DealerDecisionJob.perform_later(purchase_order.id, "reject")
          logger_info("Auto-rejected PO ID: #{purchase_order.id}")
        end
      end

      logger_info("Script completed at #{Time.now}")
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
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
agent = AutoRejectUnattendedDealerOrders.new
agent.start_processing
