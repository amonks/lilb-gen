# lilb.rb

require 'sinatra'
require 'sinatra/contrib'
require 'maruku'
require 'execjs'
require 'haml'
require 'open-uri'
require 'sass'

# spider.rb

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

def get_all_lyrics_by(artist,out)
	# lyricswiki encodes lyrics as individual html entities. get ready to parse!
	coder = HTMLEntities.new

	# open songs list, if song has lyrics add them to String 'lyrics'
	doc = Nokogiri::HTML(open("http://lyrics.wikia.com/api.php?func=getSong&artist=" + artist + "&fmt=html"))
	lyrics = String.new
	doc.xpath('//li/ul/li/a').map  { |link| link['href'] }.each do |href|
		# only add url to array if lyricswiki has the lyrics
		if remote_file_exists?(href)
			songdoc = Nokogiri::HTML(open(href))
			# get lyricsbox
			lyricsbox = songdoc.xpath('//div[@class="lyricbox"]')
			# replace br tags with periods so we can safely strip extra lyricswiki tags
			lyricsbox.css('br').each{ |br| br.replace ". " }
			# strip extra tags, remove rapgenius attribution, switch all stops to periods, remove anything in brackets (ie [chorus]), remove quotes and commas, decode entities, and add to lyrics string
			lyrics = lyrics + coder.decode(lyricsbox.xpath('text()').to_s.gsub("Lyrics taken from rapgenius.com","").gsub(/[\.\!\?]/,". ").gsub(" .", "").gsub(/[\[].*[\]]/,"").gsub(/[\"\'\,]/,"").gsub("\n",""))
			# woo progress
			# I need to find out how to stream this so I stop getting timeouts
			out.write href
		end
	end

	return lyrics
end


# woo sinatra

get '/' do
	@lyrics = open("http://monks.co/up/lyrics.txt").read
	@artist = "Lil B"
	haml :generate
end

get '/artist/*' do
	stream do |out|
		@artist = params[:splat].to_s.gsub(/[^0-9a-z_ ]/i, '')
		coder = HTMLEntities.new

		# open songs list, if song has lyrics add them to String 'lyrics'
		doc = Nokogiri::HTML(open("http://lyrics.wikia.com/api.php?func=getSong&artist=" + @artist + "&fmt=html"))
		lyrics = String.new
		doc.xpath('//li/ul/li/a').map  { |link| link['href'] }.each do |href|
			# only add url to array if lyricswiki has the lyrics
			if remote_file_exists?(href)
				songdoc = Nokogiri::HTML(open(href))
				# get lyricsbox
				lyricsbox = songdoc.xpath('//div[@class="lyricbox"]')
				# replace br tags with periods so we can safely strip extra lyricswiki tags
				lyricsbox.css('br').each{ |br| br.replace ". " }
				# strip extra tags, remove rapgenius attribution, switch all stops to periods, remove anything in brackets (ie [chorus]), remove quotes and commas, decode entities, and add to lyrics string
				lyrics = lyrics + coder.decode(lyricsbox.xpath('text()').to_s.gsub("Lyrics taken from rapgenius.com","").gsub(/[\.\!\?]/,". ").gsub(" .", "").gsub(/[\[].*[\]]/,"").gsub(/[\"\'\,]/,"").gsub("\n",""))
				# woo progress
				# I need to find out how to stream this so I stop getting timeouts
				out.write href
			end
		end

		@lyrics = lyrics
		haml :generate
	end
end

get '/stylesheets/style.css' do
	sass :style
end