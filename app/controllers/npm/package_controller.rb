class NPM::PackageController < NPMController
  before_action -> { set_npm_packages(mix_npm_packages) }
  after_action :set_headers

  rescue_from Exception, with: -> { @errors << "invalid request" and show }

  def show
    render body: @errors.any? ? @errors.flatten : @packages.map{ |package| package.entry.content.raw }
  end

  private
  def set_npm_packages(packages)
    @packages ||= []
    @errors  ||= []

    packages.map { |package|
      match = package.match(/^((?:@[^\/@]+\/)?[^\/@]+)(?:@([^\/]+))?(\/.*)?$/)

      NPM::Package.new(
        # @org/name || name
        name: match[1],
        # @version
        version: match[2] || 'latest',
        # path/to/file
        path: match[3],
        # npm/(css|js)
        extention: npm_params[:ext],
        # enviroment
        enviroment: npm_params[:env] || 'production',
      )
      
    }.each do |npm_package|
      
      if npm_package.valid? && npm_package.entry&.valid? && npm_package.entry&.content&.valid?

        # load dependencies if npm package depend
        # set_npm_packages(npm_package.dependencies.keys) if npm_package.dependencies?

        @packages << npm_package

      else
        @errors << (npm_package.errors.full_messages + npm_package.entry.errors.full_messages) << "\n"
      end
    end
  end

  def mix_npm_packages
    packages = []

    if npm_params[:mix].present?
      npm_params[:mix].split(',').each { |package|
        if package.include?(" ")
          # a+path/to/file => a,a/path/to/file
          # ex: slick-carousel+dist/slick/slick-theme => [slick-carousel, slick-carousel/dist/slick/slick-theme]
          join = package.split(/\s/)
          base = join.first

          packages << base
          
          join.drop(1).each do |slice|
            packages << "#{base.starts_with?('@') ? base.split('/')[0] : base}/#{slice}"
          end
          
        else
          packages << package
        end
      }

    else
      packages << npm_params[:path]
    end

    packages.uniq
  end

  def set_headers
    expires_in(1.year, public: true)
    response.set_header('Content-Type', "#{@packages&.first&.entry&.mime_type || 'text/plain'}; charset=utf-8")
  end
end
