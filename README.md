# Fake lyrics generator! Also lyricswiki spider!

## a nifty 1-day project by Andrew Monks

Give it an artist (by url, ie http://lyrics.monks.co/daft_punk), and it'll use Markov Chains to generate some fake lyrics that could be by that artist.

When it gets a new artist for the first time, it adds it to the database and eventually a worker thread downloads all the available lyrics from lyricswiki for that artist.

This is cool for a bunch of reasons:

1. Because an artist is only added to the db if there's at least 1 song with lyrics on lyricswiki, I don't really have to care about spambots.

2. Once it's been up for a while, I'll have scraped myself a pretty decent lyrics database based on the artists people look up.

3. It's futureproof: I don't have to worry about Hot New Bands, again because I'm relying on Lyricswiki.

### issues:

* 	right now if the spider thread is interrupted somehow, that artist is forever stuck in the database without lyrics. The cleanest solution is probably to store lyrics as a hash of songs rather than as a full string, so that A) lyrics can still be generated from a partial crawl and B) a new instance of the spider can resume rather than restarting. Plus I'd be able to react to newly added lyrics better.