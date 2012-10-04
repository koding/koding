var fmt = require('fmt');
var commander = require('commander');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var Twitter = awssum.load('twitter/twitter').Twitter;

var env            = process.env;
var consumerKey    = env.TWITTER_CONSUMER_KEY;
var consumerSecret = env.TWITTER_CONSUMER_SECRET;
var token          = env.TWITTER_TOKEN;
var tokenSecret    = env.TWITTER_TOKEN_SECRET;
// don't need the verifier

var twitter = new Twitter({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});

twitter.setToken(token);
twitter.setTokenSecret(tokenSecret);

fmt.field('ConsumerKey', twitter.consumerKey()                          );
fmt.field('ConsumerSecret', twitter.consumerSecret().substr(0, 3) + '...'  );
fmt.field('Token', twitter.token()                                );
fmt.field('TokenSecret', twitter.tokenSecret().substr(0, 3) + '...'     );

var data = {
    id : '21947795900469248',
};

twitter.RetweetedBy(data, function(err, data) {
    fmt.msg('\ncalling statuses/:id/retweeted_by - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

twitter.RetweetedByIds(data, function(err, data) {
    fmt.msg('\ncalling statuses/:id/retweeted_by/ids - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

twitter.Retweets(data, function(err, data) {
    fmt.msg('\ncalling statuses/retweets/:id - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

twitter.Show(data, function(err, data) {
    fmt.msg('\ncalling statuses/show/:id - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

data.omit_script = true; // for lols
twitter.OEmbed(data, function(err, data) {
    fmt.msg('\ncalling statuses/oembed - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});
