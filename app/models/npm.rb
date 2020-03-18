require 'net/http'
require 'open-uri'

class NPM
  include ActiveModel::Model
  include ActiveModel::Callbacks
  include ActiveModel::Validations::Callbacks

  private
  REGISTRY_URL = 'https://registry.npmjs.org'

  def dev?
    Rails.env.development?
  end

  def minname
    '.min'
  end
end
