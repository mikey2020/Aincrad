require 'pry'
class WelcomeController < ApplicationController
  def index
    respond_to do |format|
      format.json { render json: {"message": "Welcome to aincrad"} }
      format.html { render json: {"message": "Welcome to aincrad"} }
    end
  end
end
