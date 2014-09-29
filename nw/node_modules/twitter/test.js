var Twitter = require('./lib/twitter');

var twit = new Twitter({
    consumer_key: process.env.TWITTER_FUEL_TWITTER_CONSUMER_KEY,
    consumer_secret: process.env.TWITTER_FUEL_TWITTER_CONSUMER_SECRET,
    access_token_key: process.env.TWITTER_FUEL_TWITTER_ACCESS_TOKEN_KEY,
    access_token_secret: process.env.TWITTER_FUEL_TWITTER_ACCESS_TOKEN_SECRET
});

twit.search('node OR #node', function(data) {
  console.log(data);
});
