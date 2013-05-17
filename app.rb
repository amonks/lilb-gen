# lilb.rb

require 'sinatra'
require 'maruku'
require 'execjs'
require 'haml'
require 'open-uri'
require 'sass'
require 'datamapper'
require 'htmlentities'
require 'nokogiri'
require 'open-uri'
require 'net/http'

# DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_AMBER_URL'] || "sqlite3://#{Dir.pwd}/recall.db")
DataMapper.setup(:default, 'sqlite::memory:')

class Artist
	include DataMapper::Resource

	property :name, 		String
	property :lyrics, 		String
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
class Artist
	def self.get_lyrics

		# lyricswiki encodes lyrics as individual html entities. get ready to parse!
		coder = HTMLEntities.new

		# open songs list, if song has lyrics add them to String 'lyrics'
		doc = Nokogiri::HTML(open("http://lyrics.wikia.com/api.php?func=getSong&artist=" + self.name + "&fmt=html"))
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

		self.all(:lyrics => lyrics)
		self.all(:haslyrics => true)
		self.all(:lyrics_at => Time.now)
	end
end



# background thread for lyrics downloading
Thread.new do
	while true do 
		Artist.first(:haslyrics => false).get_lyrics
	end
end


# woo sinatra

get '/' do
	@lyrics = open("http://monks.co/up/lyrics.txt").read
	@artist = "Lil B"
	haml :generate
end

get '/artist/*' do
	# get/clean input
	artistinput = params[:splat].to_s.gsub(/[^0-9a-z_ ]/i, '')
	# title case
	artistinput.gsub(/\w+/) do |word|
	  word.capitalize
	end

	# get artist
	@artist = Artist.get(artistinput)

	# if artist isn't in database, add it to the database and redirect 
	if @artist.exists == false
		Artist.create(:name => artistinput, :lyrics => nil, :haslyrics => false, :created_at => Time.now, :lyrics_at => Time.now)
		redirect '/'
	# if artist is in the database and has lyrics, markov up
	elsif @artist.haslyrics == true
		@lyrics = @artist.lyrics
		haml :generate
	# if artist is in the database but doesn't yet have lyrics, redirect
	else
		redirect '/'
	end
end

get '/stylesheets/style.css' do
	sass :style
end