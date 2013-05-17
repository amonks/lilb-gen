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

def get_all_lyrics_by(artist)

	# lyricswiki encodes lyrics as individual html entities. get ready to parse!
	coder = HTMLEntities.new

	# until I figure out where to put this so it doesn't timeout i'm just gonna run with lyrics in a .txt file

	# open songs list; make array of song urls
	# worth doing this every load in case new lyrics have been added
	doc = Nokogiri::HTML(open("http://lyrics.wikia.com/api.php?func=getSong&artist=" + artist + "&fmt=html"))
	songs = Array.new
	doc.xpath('//li/ul/li/a').map  { |link| link['href'] }.each do |href|
		# only add url to array if lyricswiki has the lyrics
		if remote_file_exists?(href)
			songs.push(href)
			puts "added " + href
		end
	end

	# string to hold all lyrics
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

	return lyrics
end

# get all lil B lyrics
output = get_all_lyrics_by("Lil_B")

# and write them to a .txt file
File.open("public/lyrics.txt", 'w') {|f| f.write(output.encode('ascii', :invalid => :replace, :undef => :replace, :replace => '_')) }