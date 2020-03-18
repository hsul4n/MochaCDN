require 'net/http'
require 'open-uri'
require 'rubygems/package'

class NPMController < ApplicationController
  
  private
  def npm_params
    params.permit(:path, :ext, :hub, :mix, :env) #:depend, :beta
  end

    # files = []
    
    # Dir.entries("vendor").reject { |file| 
    #   file.starts_with?('.') || ['.', '..'].include?(file) || File.extname(file) != '.json'
    # }.each do |file|
    #   files << File.basename(file, '.*')
    # end

    # return files

   # Strips Comments
  #  $string = preg_replace('!/\*.*?\*/!s','', $string);
  #  $string = preg_replace('/\n\s*\n/',"\n", $string);

  #  # Minifies
  #  $string = preg_replace('/[\n\r \t]/',' ', $string);
  #  $string = preg_replace('/ +/',' ', $string);
  #  $string = preg_replace('/ ?([,:;{}]) ?/','$1',$string);

  #  # Remove semicolon
  #  $string = preg_replace('/;}/','}',$string);

  # ex: mix=*favor (bootstrap and its depend)
  # def tags
  #   @tags ||= {
  #     flavr: ['jquery','popper.js','bootstrap'],
  #     # design: #d3,
  #     slick: 'slick-carousel',
  #     owl: 'owl-carousel',
  #     popper: 'popper.js',
  #     animate: 'animate.css',
  #   }
  # end

  # npm_params[:mix].split(',').each { |package|
  #   # a+path/to/file => a,a/path/to/file
  #   # ex: slick-carousel+dist/slick/slick-theme => [slick-carousel, slick-carousel/dist/slick/slick-theme]
  #   if package.include?(' ')
  #     splited = package.split(' ')
  #     mixture << splited[0] << "#{splited[0]}/#{splited[1]}"
  #   else
  #     mixture << package
  #   end
  # }

  # mixture.map! { |package|
  #   # *package => find if include in tags
  #   # ex: *slick => slick-carousel
  #   if package.starts_with?('*')
  #     splited = package.split('/')
  #     name = splited[0].delete('*')
  #     # p splited[1..-1].join('/')
  #     package = "#{tags[:"#{name}"]}/#{splited[1..-1].join('/')}" if tags.keys.include?(:"#{name}")
  #   end

  #   p package

  #   # a,b,c => [a,b,c]
  #   # ex: bootstrap, jquery => [bootstrap, jquery]
  #   # if package.include?(',')
  #   #   package = package.split(',')
  #   # end

  #   package
  # }
end
