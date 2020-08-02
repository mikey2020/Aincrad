require 'rails_helper'

RSpec.describe "Welcomes", type: :request do

  describe "GET /index" do
    it "returns http success when in json format" do
      get "/welcome/index", params: { format: "json" }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /" do
    it "returns http success when in html format" do
      get "/"
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).keys).to include("message")
    end
  end

end
