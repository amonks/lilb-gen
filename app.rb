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

# DataMapper.setup(:default, 'sqlite::memory:')
# DataMapper.setup(:default, 'sqlite:///Users/ajm/Desktop/lilb-gen/data.db')
DataMapper.setup(:default, ENV['DATABASE_URL'])

class Artist
	include DataMapper::Resource

	property :name, 		String, :key => true
	property :lyrics, 		Text, :length => 500000
	property :haslyrics,	Boolean
	property :created_at,	DateTime
	property :lyrics_at,	DateTime
end

DataMapper.finalize
DataMapper.auto_upgrade!


class String
  def titlecase
    split('_').map(&:capitalize).join(' ')
  end
end

# to check if lyricswiki has the lyrics to a particular song
def remote_file_exists?(url)
  url = URI.parse(url)
  Net::HTTP.start(url.host, url.port) do |http|
    return http.head(url.request_uri).code == "200"
  end
end

# method to gather lyrics for artist
def add_lyrics_to(input)
	@artist = Artist.first(:name => input)
	# lyricswiki encodes lyrics as individual html entities. get ready to parse!
	coder = HTMLEntities.new
	sofar = String.new
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
			# strip extra tags, remove rapgenius attribution, switch all stops to periods, remove anything in brackets or parens (ie [chorus]), remove quotes slashes and commas, decode entities, and add to lyrics string
			lyrics = coder.decode(lyricsbox.xpath('text()').to_s.gsub("Lyrics taken from rapgenius.com","").gsub(/[\.\!\?]/,". ").gsub(" .", "").gsub(/[\(\[].*[\)\]]/,"").gsub(/[\"\'\/\,]/,"").gsub("\n",""))
			# woo progress
			puts "added " + href
		end
		lyrics = sofar + lyrics
		@artist.update(:lyrics => lyrics)
		sofar = lyrics
	end

	# self.update(:lyrics => lyrics, :haslyrics => true, :lyrics_at => Time.now)
	# self.save
end



# background thread for lyrics downloading
$testcount = 0

# Thread.new do
# 	while true do 
# 	    sleep 0.12
# 		$testcount += 1
# 		artist = Artist.last(:haslyrics => false)
# 		if artist.nil? == false
# 			lyrics = get_all_lyrics_by(artist.name)
# 			puts lyrics
# 			artist.update(:lyrics => lyrics)
# 			artist.update(:haslyrics => true)
# 		end
# 	end
# end


# stylesheets duh
get '/stylesheets/style.css' do
	sass :style
end

# default to Lil B
get '/' do
	redirect '/lil_b'
end

get '/lyrics/*' do
	# get/clean input
	artistinput = params[:splat].to_s.gsub(/[^0-9a-z_ ]/i, '').downcase.gsub(/\s\s*/,"_")
	# get artist
	@artist = Artist.first(:name => artistinput)
	haml :lyrics
end

# woo clear the whole database FUCK IT
get '/admin/reset' do
	Artist.destroy!
end

# for the form
post '/*' do
	redirect '/' + params[:artist]
end

# put all the other stuff before the WiLdCaRd
get '/*' do
	# get/clean input
	artistinput = params[:splat].to_s.gsub(/[^0-9a-z_ ]/i, '').downcase.gsub(/\s\s*/,"_")
	# get artist
	artist = Artist.first(:name => artistinput)

	# create artist if doesn't exist
	if artist.nil?
		artist = Artist.create(:name => artistinput, :lyrics => nil, :haslyrics => false, :created_at => Time.now, :lyrics_at => Time.now)
		Thread.new do
			lyrics = add_lyrics_to(artist.name)
			artist.update(:haslyrics => true)
		end
		@artist = artist
		@allartists = Artist.all(:lyrics.not => nil)
		haml :newartist
	# if artist has lyrics show the lyrics
	elsif artist.lyrics.nil? == false and artist.lyrics.length >= 10
		@artist = artist
		@lyrics = @artist.lyrics
		haml :generate
	else
		@artist = artist
		@allartists = Artist.all(:lyrics.not => nil)
		haml :notyet
	end
end
