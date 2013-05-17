# lilb.rb

require 'sinatra'
require 'maruku'
require 'execjs'
require 'haml'
require 'sass'

require 'htmlentities'
require 'nokogiri'
require 'open-uri'
require 'net/http'

# to check if lyricswiki has the lyrics to a particular song
def remote_file_exists?(url)
  url = URI.parse(url)
  Net::HTTP.start(url.host, url.port) do |http|
    return http.head(url.request_uri).code == "200"
  end
end

# lyricswiki encodes lyrics as individual html entities. get ready to parse!
coder = HTMLEntities.new

# lolololol every request is gonna take like 3 minutes this is a problem
before do
	# open Lil B songs list; make array of song urls
	# worth doing this every load in case new lyrics have been added
	doc = Nokogiri::HTML(open("http://lyrics.wikia.com/api.php?func=getSong&artist=Lil_B&fmt=html"))
	songs = Array.new
	doc.xpath('//li/ul/li/a').map  { |link| link['href'] }.each do |href|
		# only add url to array if lyricswiki has the lyrics
		if remote_file_exists?(href)
			songs.push(href)
			puts "added " + href
		end
	end

	# string to hold all lyrics for markoving
	lyrics = String.new
	# open each song
	songs.each do |song|
		doc = Nokogiri::HTML(open(song))
		# get lyricsbox
		lyricsbox = doc.xpath('//div[@class="lyricbox"]')
		# replace br tags with periods so we can safely strip extra lyricswiki tags
		lyricsbox.css('br').each{ |br| br.replace ". " }
		# strip extra tags, add newlines after punctuation (for readability i guess), decode entities, and add to lyrics string
		lyrics = lyrics + coder.decode(lyricsbox.xpath('text()').to_s.gsub(/[\.\!\?]/,". \n"))
	end
end


get '/' do
	@lyrics = lyrics
	haml :generate
end

get '/stylesheets/style.css' do
  sass :style
end

