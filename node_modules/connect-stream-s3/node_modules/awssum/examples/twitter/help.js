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

twitter.Test(function(err, data) {
    console.log('\ncalling help/test - expecting success');
    inspect(err, 'Err');
    inspect(data, 'Data');
});

twitter.Configuration(function(err, data) {
    console.log('\ncalling help/configuration - expecting success');
    inspect(err, 'Err');
    inspect(data, 'Data');
});

twitter.Languages(function(err, data) {
    console.log('\ncalling help/languages - expecting success');
    inspect(err, 'Err');
    inspect(data, 'Data');
});
