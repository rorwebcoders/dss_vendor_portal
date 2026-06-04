require 'net/http'
require 'uri'
require 'json'

class SkuMonsterClient
  def self.block_dealer_inventory!(request_body:)
    post(request_body)
  end

  def self.post(payload)
    order_rejected_api_url = Rails.application.credentials[Rails.env.to_sym][:order_rejected_api_url]
    skumonster_api_token = Rails.application.credentials[Rails.env.to_sym][:skumonster_api_token]

    uri = URI(order_rejected_api_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Authorization"] = skumonster_api_token
    request["Content-Type"] = "application/json"
    request.body = payload.to_json
    response = http.request(request)

    puts "Status Code: #{response.code}"
    puts "Response Body:"
  end
end