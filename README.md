#	lil b song generator wooooooooo

## get/parse the lyrics

spider.rb is the first step, it grabs all of the lil b lyrics from lyricswiki and sticks them in a text file

## do the markov dealy

views/generate.haml gets the lyrics from spider.rb and then uses execjs and gibgen.js to markov it up