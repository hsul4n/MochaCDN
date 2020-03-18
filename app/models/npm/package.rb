class NPM::Package < NPM
  # @scope/name|name
  attr_accessor :name
  # @version
  attr_accessor :version
  # /path/to/file
  attr_writer :path
  # extention (js|css), etc..
  attr_writer :extention
  # enviroment (development|production)
  attr_accessor :enviroment

  validates_with NameValidator
  validates_with VersionValidator, if: -> { registry.present? }

  validates_inclusion_of :enviroment, in: %w(development production), allow_blank: true

  # unzip entry when finish validating package and no error found
  after_validation -> { entry.unzip if errors.empty? }

  def attributes=(hash)
    hash.each do |key, value|
      send(key, value)
    end
  end

  def id
    "#{name}@#{version}"
  end
  
  def entry
    @entry ||= Entry.new(package: self)
  end

  # if extention not present find from path 
  # npm/[extention] or npm/file/to/path.[extention] 
  def extention
    @extention.present? ? ".#{@extention}" : File.extname(@path)
  end

  # if path and extention are present add `extention`
  # ex: npm/[extention]?mix=[name/file/to/path] << `extention`
  def path
    @extention.present? && @path.present? ? "#{@path}#{extention}" : @path
  end

  def latest?
    version == 'latest'
  end

  def scoped?
    name.starts_with?('@')
  end
  
  def minify?
    production? && mix?
  end

  def mix?
    @extention.present?
  end

  def file?
    !mix?
  end

  def css?
    @extention == 'css'
  end

  def js?
    @extention == 'js'
  end

  def development?
    enviroment == 'development'
  end

  def production?
    enviroment == 'production'
  end

  def dependencies
    version_registry['dependencies'] || version_registry['peerDependencies'] if js?
  end

  def dependencies?
    dependencies.present?
  end
  
  def tarball_name
    scoped? ? name.split('/')[1] : name
  end
  
  def tarball_url
    (dev? ? "vendor/" : "#{REGISTRY_URL}/#{name}/-/") << "#{tarball_name}-#{version}.tgz"
  end

  def registry
    @registry ||= JSON.parse(open(dev? ? "vendor/#{tarball_name}.json" : "#{REGISTRY_URL}/#{name}").read) rescue nil
  end

  def version_registry
    registry['versions'][version] rescue nil
  end
end
