class NPM::Package::Entry < NPM
  define_model_callbacks :find, only: :after
  
  # NPM::Package
  attr_accessor :package
  # NPM::Package::Entry::Content
  attr_reader :content
  # Archive::Tar::Minitar::Reader
  attr_reader :minitar

  validate -> { errors.add(:base, "Couldn't find #{package.extention.present? ? package.extention.delete('.') : 'file'} #{'in `' << package.path << '`' rescue 'file'} for #{package.id}") unless content.present? }

  after_find -> { content&.parse }

  def unzip
    begin
      io = open(package.tarball_url)

      # GzipReader handles uncompressing the tgz file, and any attempts 
      # to read from it will return the uncompressed contents of that file.
      gzip_reader = dev? ? Zlib::GzipReader.open(io) : Zlib::GzipReader.new(io)
      # gzip_reader = Zlib::GzipReader.open(open(package.tarball_url))
      # gzip_reader = Zlib::GzipReader.open(open(dev? ? "vendor/#{package.tarball_name}-#{package.version}.tgz" : package.tarball_url))

      # Minitar uses POSIX indicates that "A POSIX-compliant implementation must treat any unrecognized typeflag value as a regular file."
      # When using Gem::Package::TarReader it raises when octal string found such as using `jqueryui` package
      @minitar = Archive::Tar::Minitar::Reader.open(gzip_reader)

      find(path: self.path)

      # Try to find minfied version or minify manually
      find(path: minified_path) || content&.minify if minify?

      run_callbacks :find

      gzip_reader.close
      minitar.close
    rescue
    end
  end
  
  # path/to/entry
  def path
    # use package path unless find
    @path ||= package.path || find_path
  end

  # path/to/file[.extention]: path/to/file.min.extention
  def minified_path
    path.gsub(/#{package.extention}$/) { |extention| minname << extention }
  end

  def mime_type
    Mime::Type.lookup_by_extension(extention)
  end

  def find(path:, by: find_by.first)
    try = find_by.find_index(by)
    minify = File.basename(path).include?(minname)

    # rewinds to the beginning of the minitar and re find file 
    minitar.rewind

    # NPM::Package::Entry::Content
    found_entry = nil

    # return if minify & previous try was find by minify
    return if minify && find_by[try - 1] == :minified

    minitar.each_entry do |entry|

      # ignore directory entries or files that been fixed by Minitar and appended with `PaxHeader`
      next if entry.directory? || entry.name.starts_with?('PaxHeader')

      # most packages have header names that look like `package/index.js`
      # so we shorten that to just `index.js` here. A few packages use a
      # prefix other than `package/`. e.g. the firebase package uses the
      # `firebase_npm/` prefix. So we just strip the first dir name.
      entry_path = entry.name.gsub(/^[^\/]+/, '')

      # path from entry_path
      entry_filename = File.basename(entry_path)
      
      dirname = File.dirname(path)
      filename = File.basename(path)

      if by == :path
        # first priority using `main` or `style` keys from `package.json`
        # ex: path/to/file.extention, path/to/file
        found_path = entry_path if entry_path == path #entry_path.starts_with?(path) && 
        
      else
        
        # ignore unmatched extentions and start with undersocre
        next if File.extname(entry_path) != package.extention || entry_filename.starts_with?('_')

        case by
        
        when :filename
          # path/to/file.extention, filename.extention
          # [path/to/express.extention, express.extention]
          found_path = entry_path if (["#{dirname}/#{filename}#{package.extention}", "#{filename}#{package.extention}"] & [entry_path, entry_filename]).present?

        when :minified
          # path/to/file.min.extention, filename.min.extention
          # [path/to/equalizecss.min.extention, equalizecss.min.extention]
          found_path = entry_path if (["#{dirname}/#{filename}#{minname}#{package.extention}", "#{filename}#{minname}#{package.extention}"] & [entry_path, entry_filename]).present?

        when :kebab
          # path/to/file-name.extention, file-name.extention
          # [denali.extention, css.extention]
          found_path = entry_path if filename.split('-').map { |item| item << package.extention }.include?(entry_filename)

        when :dotted
          # path/to/file.name.extention, file.name.extention
          # [jquery, fancybox, pack] at least 2 exists
          found_path = entry_path if (filename.split('.') & entry_filename.split('.')).length > 1
          
        when :style
          # path/to/style.css, style.css
          # [path/to/icomoon/style.css, style.css]
          found_path = entry_path if (["#{dirname}/style.css", "style.css"] & [entry_path, entry_filename]).present?
        
        when :all
          # path/to/style.css, style.css
          # [path/to/jquery-ui/all.css, all.css]
          found_path = entry_path if (["#{dirname}/all.css", "all.css"] & [entry_path, entry_filename]).present?
        
        when :index
          # path/to/index.extention, index.extention
          # [path/to/chalk/index.extention, index.extention]
          found_path = entry_path if (["#{dirname}/index#{package.extention}", "index#{package.extention}"] & [entry_path, entry_filename]).present?
        end
      end

      found_entry = { path: entry_path, content: entry.read } if found_path.present?
    end

    # return if entry not found and tries not execeted
    return find(path: path, by: find_by[try + 1]) if !found_entry.present? && try != (find_by.size - 1)

    if found_entry.present?
      @path = found_entry[:path]
      # @content = nil if minify.present?
      # (@content ||= []) << found_entry
      @content = Content.new(entry: self, raw: found_entry[:content])

      Rails.logger.info "#{package.name} found#{minify ? " minified" : ""} by #{by} at: #{path}"

      return true

    else
      Rails.logger.info "#{package.name}#{minify ? " minified" : ""} not found"

      return false
    end
  end

  private
  def find_by 
    unless @find_by.present?
      @find_by = [:path]

      # ignore suggestions if path presents
      unless package.path.present?
        @find_by += [:filename, :minified, :kebab, :dotted, :index] 
        # add style, all before index for more priority
        @find_by.insert(5, :style, :all) if package.css?
      end
    end

    @find_by
  end

  def find_path
    registry = package.version_registry

    # search for style if exists
    found_path = registry['style'] if package.css? && registry.include?('style')

    # if not present check `unpkg, jsdelivr, main` keys unless use package name
    found_path ||= registry['unpkg'] || registry['jsdelivr'] || registry['main'] || package.name

    # remove ./ because some packages has ./ at begging
    '/' << (File.dirname(found_path) << '/' << File.basename(found_path, '.*')).remove('./') << package.extention
  end

  def minify?
    # if package need minify and entry path not minified yet!
    package.minify? && !File.basename(path).include?(minname)
  end

  # path/to/file.extention: extention
  def extention
    File.extname(path).delete('.')
  end
end