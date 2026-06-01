require "net/http"
require "uri"
require "json"

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
    request_body = build_payload(purchase_order).to_json
    request.body = request_body
    response = http.request(request)

    unless [200, 201].include?(response.code.to_i)
      raise "ShipStation Label Error: #{response.body}"
    end

    body = JSON.parse(response.body) rescue {}

    {
      tracking: body["trackingNumber"],
      label_url: body["labelData"]
    }
  end

private
  def self.build_payload(po)
    {
      carrierCode: "fedex",
      serviceCode: "fedex_ground",
      packageCode: "package",
      shipDate: Time.current.strftime("%Y-%m-%d"),
      weight: {
        value: po.weight,
        units: po.units
      },
      dimensions: {
        units: "inches",
        length: po.length || 12,
        width: po.width || 10,
        height: po.height || 8
      },
      shipFrom: {
        name: po.dealer.dealer_name,
        street1: po.dealer.dealer_address1,
        city: po.dealer.dealer_city,
        state: po.dealer.dealer_state,
        postalCode: po.dealer.dealer_zip,
        country: po.dealer.dealer_country
      },
      shipTo: {
        name: po.shipping_name,
        street1: po.shipping_address1,
        city: po.shipping_city,
        state: po.shipping_state,
        postalCode: po.shipping_zip,
        country: po.shipping_country
      }
    }
  end
end