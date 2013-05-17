# lilb.rb

require 'sinatra'
require 'maruku'
require 'execjs'
require 'haml'
require 'sass'
require 'open-uri'



get '/' do
	@lyrics = open("http://monks.co/up/lyrics.txt").read.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_')
	haml :generate
end

get '/stylesheets/style.css' do
  sass :style
end