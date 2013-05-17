# # lilb.rb
# require 'sinatra'
# require 'maruku'
# require 'execjs'
# require 'haml'
# require 'sass'

require 'htmlentities'
require 'nokogiri'
require 'open-uri'
require 'net/http'


def remote_file_exists?(url)
  url = URI.parse(url)
  Net::HTTP.start(url.host, url.port) do |http|
    return http.head(url.request_uri).code == "200"
  end
end


coder = HTMLEntities.new


doc = Nokogiri::HTML(open("http://lyrics.wikia.com/api.php?func=getSong&artist=Lil_B&fmt=html"))
songs = Array.new
doc.xpath('//li/ul/li/a').map  { |link| link['href'] }.each do |href|
	if remote_file_exists?(href)
		songs.push(href)
		puts "added " + href
	end
end

lyrics = String.new
songs.each do |song|
	print song
	doc = Nokogiri::HTML(open(song))
	lyrics = lyrics + "\n " + coder.decode(doc.xpath('//div[@class="lyricbox"]').xpath('text()').to_s)
end


print lyrics


# get '/' do
# 	@lyrics = lyrics
# 	haml :generate
# end

# get '/stylesheets/style.css' do
#   sass :style
# end

