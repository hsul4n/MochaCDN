class NPM::Package::Entry::Content < NPM
  # NPM::Package::Entry
  attr_accessor :entry
  attr_accessor :raw

  def parse
    beautify if entry.package.mix?
  end

  def present?
    raw.present?
  end

  # private
  # /import.*".*"/
  # ES6_IMPORT_PATTERN = /import{*[^}]*}.*/
  CSS_IMPORT_PATTERN = /@import.*(;|"|\))$/
  CSS_URL_PATTERN = /url\((?!['"]?(?:data|http):)['"]?([^'"\)]*)['"]?\)/
  SOURCE_MAP_URL_PATTERN = /sourceMappingURL=.*\w/
  # (url\((?!['"]?(?:data|http):)['"]?([^'"\)]*)['"]?\))|(@import.?".*")
  def loader
    if load?
      dirname = Pathname.new(entry.path).dirname
      files = []    
      
      if entry.package.css?
        @raw = raw.gsub(CSS_IMPORT_PATTERN) { |import|
          files << "#{dirname.join(import.match(/"([^"]*)"/)[0].delete('"'))}"

          ""
        }.strip << "\n"

        files.each do |file|
          entry.find(path: file)
        end
        
      end
    end
  end

  def minify
    if present?
      # if break line present
      if raw.strip.include?("\n")
        if entry.package.js?
          @raw = Uglifier.new(harmony: true).compile(raw.force_encoding(Encoding::UTF_8))
        elsif entry.package.css?
          @raw = Sass::Engine.new(raw, syntax: :scss, style: :compressed).render
        end
        Rails.logger.info "minified"
      else
        Rails.logger.info "already minfied"
      end
    end
  end

  def beautify
    dirname = Pathname.new("#{entry.package.name}#{entry.path}").dirname

    raw.force_encoding(Encoding::UTF_8)
    
    # remove byte order marker (dom) characters
    raw.sub!(/\xEF\xBB\xBF/, '')

    # replace url with entry.package/path/to/path
    raw.gsub!(CSS_URL_PATTERN) { |url| "url(\"#{dirname.join(url[5...-2])}\")" } if entry.package.css?

    # replace mapping url with entry.package/entry/url
    raw.sub!(/sourceMappingURL=.*\w/) { |url| "sourceMappingURL=#{dirname.join(url[17..-1])}" }

    # remove break lines
    raw.strip!

    # add break line
    raw << "\n"
  end
end