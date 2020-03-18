class NPM::Package::Entry::Content < NPM
  # NPM::Package::Entry
  attr_accessor :entry
  attr_accessor :raw

  def parse
    beautify if entry.package.mix?
    # loader { |file| entry.find(path: file) } if load?
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

    # if package.css?
      
    #   dirname = Pathname.new("#{package.name}#{path}").dirname
    #   # replace url with package/entry/url
    #   # powerful when call fonts, images, etc..
    #   @content = content.gsub(CSS_URL_PATTERN) { |url|
    #     # "url(\"#{dirname.join(url[5...-2])}\")"
    #     url.insert(4, "#{dirname.to_s}/")
    #   }

    # end

    # return importer
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

    # remove comments
    # @https://stackoverflow.com/questions/15411263/how-do-i-write-a-better-regexp-for-css-minification-in-php
    # @content = @content.gsub(/\/\*.*?\*\//, "")
  end

  # def load?
  #   if entry.package.js?
  #     return false
  #   elsif entry.package.css?
  #     return raw =~ CSS_IMPORT_PATTERN
  #   end
  # end

  # should mix
  # if npm_package.mix?
  #   content = npm_package.entry.content
  #   dirname = Pathname.new("#{npm_package.name}#{npm_package.entry.path}").dirname

  # #   # load file from imports
  # #   # load pack

  # #   # if start with ./ file in root
  # #   # else new package

  #   if npm_package.js?
  #     content = content.gsub(/import{*[^}]*}.*/) { |import|
  #       path = import.match(/"([^"]*)"/).to_s.delete('"')

  #       # if path.starts_with?("./")
  #       #   import = import.gsub(/"([^"]*)"/, "\"./#{dirname.join(path).to_s << ".js"}\"")
  #       # else
  #       #   import = import.gsub(/"([^"]*)"/, "\"./#{path}\"")
  #       # end

  #       if import.present?
  #         path = import.match(/"([^"]*)"/).to_s.delete('"')
  #         file = nil

  #         if path.starts_with?("./")
  #           import = ""
  #           # import << "?module"
  #           file = npm_package.name << File.dirname(npm_package.entry.path) << '/' << File.basename(path)
  #           # content = content.gsub(/import{*[^}]*}.*/, '')
  #           set_npm_packages([file])
  #         else
  #           import = ""
  #           # import = import.gsub(/"([^"]*)"/, "\"./index.js\"")
  #           # content = content.gsub(/import{*[^}]*}.*/, '')
  #         end

  #       end

  #       import
  #     }

  #     begin
  #       content['export'] = ''
  #     rescue
  #     end
  #   end

  #   npm_package.entry.content = content
  # #   # npm_package.entry.beautify #change dirname in entry
  # end
  # npm_package.entry.content = File.open('vendor/a.js').read if npm_package.name.starts_with?('@rails')
  # npm_package.entry.content = Babel::Transpiler.transform(npm_package.entry.content)[:code] if npm_package.name.starts_with?('@rails')


  # /*!
  #  * name version (homepage)
  #  * Copyright created-modified author.name (author.url)
  #  * Licensed under license
  #  */
  # def header
  #   header = "/**\n  * #{name.capitalize} v#{version} (#{registry['homepage']})\n  * Copyright #{Date.parse(registry['time']['created']).year}-#{Date.parse(registry['time']['modified']).year}#{(version_registry['author']['name'] + version_registry['author']['url']&.insert(0, ' (')&.insert(-1, ')') rescue nil)&.insert(0, ' ')}\n  * Licensed under #{version_registry['license']}\n  */\n"
  #   header << "/**\n  * Mixited by @ using UglifyJS v3.3.10.\n  * Original file: #{filename}\n  * \n  * Do NOT use SRI with dynamically generated files! More information: https://www.jsdelivr.com/using-sri-with-dynamic-files\n  */\n" if minify?
  # end

  # def body
  #   remove (comments, spaces)
  #   @content = @@uglifier.compile(@content) rescue @content
  #   @content.gsub(/[\r\n]{2,}/, "\r").force_encoding("UTF-8").strip << "\n"
  #   .gsub(/\/\*[\s\S]*?\*\/|([^\\:]|^)\/\/.*$/, "").gsub(/[\r\n]{2,}/, "\r").force_encoding("UTF-8").strip << "\n"
  # end

  #/*!
  #  * End name
  #  */
  # def footer
  #   "/**\n  * End #{id}\n  */"
  # end
end