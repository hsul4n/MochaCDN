require 'net/http'
require 'open-uri'
require 'rubygems/package'

class NPMController < ApplicationController
  
  private
  def npm_params
    params.permit(:path, :ext, :hub, :mix, :env) #:depend, :beta
  end
end
