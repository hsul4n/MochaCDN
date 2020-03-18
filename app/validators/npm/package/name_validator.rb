class NPM::Package::NameValidator < ActiveModel::Validator
  def validate(package)
    if !package.name.present?
      error = "cannot be null"
    elsif package.name.class.to_s != "String"
      error = "must be a string"
    elsif !package.name.length
      error = "length must be greater than zero"
    elsif package.name.match(/^\./)
      error = "cannot start with a period"
    elsif package.name.match(/^_/)
      error = "cannot start with an underscore"
    elsif package.name.strip != package.name
      error = "cannot contain leading or trailing spaces"
    elsif package.name.length == 32 && package.name.match(/^[a-f0-9]+$/i)
      error = "cannot be a hash"
    elsif %w(node_modules favicon.ico).include?(package.name.downcase)
      error = "is a blacklisted name"
    end
      
    package.errors.add(:base, "name #{error}" << " for #{package.id}") if error.present?
  end
end