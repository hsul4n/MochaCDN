class NPM::Package::VersionValidator < ActiveModel::Validator
  def validate(package)
    # if version is latest
    if package.latest?
      package.version = package.registry['dist-tags'][package.version]

    # if selected version not exists
    elsif !package.registry['versions'].keys.include?(package.version)
      package.errors.add(:base, "Cannot find package #{package.id}")
    end
  end
end