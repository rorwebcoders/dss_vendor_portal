require 'logger'
require 'net/http'
require 'json'
require 'openssl' # Required for SSL options
require 'active_support/all' # Required for time zone operations
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
        dealer = Dealer.find_or_initialize_by(sm_dealer_id: dealer_data["id"])
        dealer_name = dealer_data["name"]
        logger_info("Processing Dealer: #{dealer_name}")
        dealer.update!(
          dealer_name: dealer_data["name"],
          abbreviation: dealer_data["abbreviation"],
          dealer_address: dealer_data["address"],
          enabled: true
        )

        active_ids << dealer_data["id"]
        logger_info("Stored Dealer: #{dealer_name}")
      end
      Dealer.where.not(sm_dealer_id: active_ids).update_all(enabled: false)
      logger_info("Script completed at #{Time.now}")
    rescue StandardError => e
      logger_error(e.message)
      logger_error(e.backtrace.join("\n"))
    end
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