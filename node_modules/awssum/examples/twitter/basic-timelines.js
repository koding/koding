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
    count            : 3,
    include_entities : true,
};

twitter.GetHomeTimeline(function(err, data) {
    fmt.msg('\ncalling statuses/home_timeline - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

twitter.GetMentions(function(err, data) {
    fmt.msg('\ncalling statuses/mentions - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

twitter.GetRetweetedByMe(function(err, data) {
    fmt.msg('\ncalling statuses/retweeted_by_me - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

twitter.GetRetweetedToMe(function(err, data) {
    fmt.msg('\ncalling statuses/retweeted_to_me - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

twitter.GetRetweetsOfMe(function(err, data) {
    fmt.msg('\ncalling statuses/retweets_of_me - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

twitter.GetUserTimeline(function(err, data) {
    fmt.msg('\ncalling statuses/user_timeline - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

twitter.GetRetweetedToUser({ screen_name : 'andychilton' }, function(err, data) {
    fmt.msg('\ncalling statuses/retweeted_to_user - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});

twitter.GetRetweetedByUser({ screen_name : 'andychilton' }, function(err, data) {
    fmt.msg('\ncalling statuses/retweeted_by_user - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});
