var inspect = require('eyes').inspector({ maxLength : 65536 });
var commander = require('commander');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var Twitter = awssum.load('twitter/twitter').Twitter;

var env = process.env;
var consumerKey = process.env.TWITTER_CONSUMER_KEY;
var consumerSecret = process.env.TWITTER_CONSUMER_SECRET;
var token = process.env.TWITTER_TOKEN;
var tokenSecret = process.env.TWITTER_TOKEN_SECRET;
// don't need the verifier

var twitter = new Twitter({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});

twitter.setToken(token);
twitter.setTokenSecret(tokenSecret);

console.log( 'ConsumerKey    :', twitter.consumerKey()                          );
console.log( 'ConsumerSecret :', twitter.consumerSecret().substr(0, 3) + '...'  );
console.log( 'Token          :', twitter.token()                                );
console.log( 'TokenSecret    :', twitter.tokenSecret().substr(0, 3) + '...'     );

var data = {
    id : '21947795900469248',
};

twitter.RetweetedBy(data, function(err, data) {
    console.log('\ncalling statuses/:id/retweeted_by - expecting success');
    inspect(err, 'Err');
    inspect(data, 'Data');
});

twitter.RetweetedByIds(data, function(err, data) {
    console.log('\ncalling statuses/:id/retweeted_by/ids - expecting success');
    inspect(err, 'Err');
    inspect(data, 'Data');
});

twitter.Retweets(data, function(err, data) {
    console.log('\ncalling statuses/retweets/:id - expecting success');
    inspect(err, 'Err');
    inspect(data, 'Data');
});

twitter.Show(data, function(err, data) {
    console.log('\ncalling statuses/show/:id - expecting success');
    inspect(err, 'Err');
    inspect(data, 'Data');
});

data.omit_script = true; // for lols
twitter.OEmbed(data, function(err, data) {
    console.log('\ncalling statuses/oembed - expecting success');
    inspect(err, 'Err');
    inspect(data, 'Data');
});
