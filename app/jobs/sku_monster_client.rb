class SkuMonsterClient
  def self.block_dealer_inventory!(request_body:)
    post("https://sm.dealersalessolutions.com/release_inventory", request_body)
  end

  def self.post(api_url, payload)
    url = URI.parse(api_url)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url.path, {
      "Content-Type" => "application/json"
    })

    request.body = payload.to_json
    response = http.request(request)

    response_data = JSON.parse(response.body)
    puts response_data
  end
end