# lilb.rb

require 'sinatra'
require 'maruku'
require 'execjs'
require 'haml'
require 'open-uri'
require 'sass'
require 'data_mapper'
require 'htmlentities'
require 'nokogiri'
require 'open-uri'
require 'net/http'

# DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_AMBER_URL'] || "sqlite3://#{Dir.pwd}/recall.db")
# DataMapper.setup(:default, 'sqlite::memory:')
DataMapper.setup(:default, 'sqlite:///Users/ajm/Desktop/lilb-gen/data.db')

class Artist
	include DataMapper::Resource

	property :name, 		String, :key => true
	property :lyrics, 		Text
	property :haslyrics,	Boolean
	property :created_at,	DateTime
	property :lyrics_at,	DateTime
end

DataMapper.finalize
DataMapper.auto_upgrade!


# to check if lyricswiki has the lyrics to a particular song
def remote_file_exists?(url)
  url = URI.parse(url)
  Net::HTTP.start(url.host, url.port) do |http|
    return http.head(url.request_uri).code == "200"
  end
end

# method to gather lyrics for artist
def get_all_lyrics_by(input)

	# lyricswiki encodes lyrics as individual html entities. get ready to parse!
	coder = HTMLEntities.new

	# open songs list, if song has lyrics add them to String 'lyrics'
	doc = Nokogiri::HTML(open("http://lyrics.wikia.com/api.php?func=getSong&artist=" + input + "&fmt=html"))
	lyrics = String.new
	doc.xpath('//li/ul/li/a').map  { |link| link['href'] }.each do |href|
		# only add url to array if lyricswiki has the lyrics
		if remote_file_exists?(href)
			songdoc = Nokogiri::HTML(open(href))
			# get lyricsbox
			lyricsbox = songdoc.xpath('//div[@class="lyricbox"]')
			# replace br tags with periods so we can safely strip extra lyricswiki tags
			lyricsbox.css('br').each{ |br| br.replace ". " }
			# strip extra tags, remove rapgenius attribution, switch all stops to periods, remove anything in brackets (ie [chorus]), remove quotes slashes and commas, decode entities, and add to lyrics string
			lyrics = lyrics + coder.decode(lyricsbox.xpath('text()').to_s.gsub("Lyrics taken from rapgenius.com","").gsub(/[\.\!\?]/,". ").gsub(" .", "").gsub(/[\[].*[\]]/,"").gsub(/[\"\'\/\,]/,"").gsub("\n",""))
			# woo progress
			# I need to find out how to stream this so I stop getting timeouts
			puts "added " + href
		end
	end

	# self.update(:lyrics => lyrics, :haslyrics => true, :lyrics_at => Time.now)
	# self.save
	return lyrics
end



# background thread for lyrics downloading
$testcount = 0
Thread.new do
	while true do 
	    sleep 0.12
		$testcount += 1
		artist = Artist.last(:haslyrics => false)
		if artist.nil? == false
			lyrics = get_all_lyrics_by(artist.name)
			puts lyrics
			artist.update(:lyrics => lyrics)
			artist.update(:haslyrics => true)
		end
	end
end


# woo sinatra

get '/stylesheets/style.css' do
	sass :style
end

get '/' do
	redirect '/lil_b'
end

get '/*' do
	# get/clean input
	artistinput = params[:splat].to_s.gsub(/[^0-9a-z_ ]/i, '').downcase

	# get artist
	artist = Artist.first(:name => artistinput)

	# create artist if doesn't exist
	if artist.nil?
		artist = Artist.create(:name => artistinput, :lyrics => nil, :haslyrics => false, :created_at => Time.now, :lyrics_at => Time.now)
		@artist = artist
		haml :newartist
	# if artist has lyrics show the lyrics
	elsif artist.haslyrics == true
		@artist = artist
		@lyrics = @artist.lyrics
		haml :generate
	elsif artist.haslyrics == false
		@artist = artist
		haml :notyet
	end
end