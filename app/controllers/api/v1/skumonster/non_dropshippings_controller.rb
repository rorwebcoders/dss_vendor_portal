FILE_PATH = Rails.root.join("public", "skumonster", "api_tokens.yml")
class Api::V1::Skumonster::NonDropshippingsController < ApplicationController
  before_action :validate_token

  def index
    responses = PurchaseOrder.where(skuvault_status: "ReadyToShip", status: :non_dropshipping).pluck(:read_to_ship_response).compact
    responses = PurchaseOrder.where(skuvault_status: "ReadyToShip").pluck(:read_to_ship_response).compact

    render json: {
      status: "success",
      results: responses
    }
  end

private
  def validate_token
    token = request.headers['Authorization'].to_s.sub(/\ABearer\s+/i, '').strip
    file_data = YAML.load_file(FILE_PATH) rescue {}
    file_data ||= {}
    expected = file_data["token"] rescue ''

    Rails.logger.info "API auth attempt header_present=#{token.present?} env_present=#{expected.present?} token_len=#{token.to_s.bytesize} env_len=#{expected.to_s.bytesize} remote_ip=#{request.remote_ip}"

	unless token == expected || expected.to_s == ""
	  render json: {
	    status: "failure",
	    error: 'Unauthorized'
	  }, status: :unauthorized
	end
  end
end
