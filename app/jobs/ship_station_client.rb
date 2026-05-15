class ShipStationClient
  def self.create_label(purchase_order)
    url = URI.parse("https://ssapi.shipstation.com/shipments/createlabel")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    shipstation_api_key = Rails.application.credentials[Rails.env.to_sym][:shipstation_api_key]
    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "Basic #{shipstation_api_key}"
    }

    request = Net::HTTP::Post.new(url.path, headers)
    request.body = build_payload(purchase_order).to_json
    response = http.request(request)

    unless response.code.to_i == 200
      raise "ShipStation Label Error: #{response.body}"
    end

    body = JSON.parse(response.body)

    {
      tracking: body["trackingNumber"],
      label_url: body["labelData"]
    }
  end

private
  def self.build_payload(params)
    {
      carrierCode: "fedex",
      serviceCode: "fedex_ground",
      packageCode: "package",
      shipDate: Time.current.strftime("%Y-%m-%d"),
      weight: {
        value: total_weight,
        units: "pounds"
      },
      dimensions: default_dimensions,
      shipFrom: {
        name: params[:dealer_name],
        street1: params[:dealer_address1],
        city: params[:dealer_city],
        state: params[:dealer_state],
        postalCode: params[:dealer_zip],
        country: params[:dealer_country]
      },
      shipTo: {
        name: params[:shipping_name],
        street1: params[:shipping_address1],
        city: params[:shipping_city],
        state: params[:shipping_state],
        postalCode: params[:shipping_zip],
        country: params[:shipping_country]
      }
    }
  end

  def self.default_dimensions
    {
      units: "inches",
      length: 12,
      width: 10,
      height: 8
    }
  end
end