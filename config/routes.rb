Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  
  # disable format to use .extname
  namespace :npm, format: false do
    # (js|css)?mix=package1,package2,package3
    get ':ext', to: 'package#show', ext: /(js|css)/
  
    # npm/package/path/to/file.ext
    get '*path', to: 'package#show'
  end

  # use
  # /js?mix=npm/package1,wp/package2,gh/package3
  # /css?mix=npm/package1,wp/package2,gh/package3
end
