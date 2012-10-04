var fmt = require('fmt');
var commander = require('commander');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var termService = awssum.load('term/term');

var env            = process.env;
var consumerKey    = env.TERM_CONSUMER_KEY;
var consumerSecret = env.TERM_CONSUMER_SECRET;
var token          = env.TERM_TOKEN;
var tokenSecret    = env.TERM_TOKEN_SECRET;
// don't need the verifier

var term = new termService.Term({
    'consumerKey' : consumerKey,
    'consumerSecret' : consumerSecret
});

term.setToken(token);
term.setTokenSecret(tokenSecret);

fmt.field('ConsumerKey', term.consumerKey()     );
fmt.field('ConsumerSecret', term.consumerSecret() );
fmt.field('Token', term.token()          );
fmt.field('TokenSecret', term.tokenSecret()    );

// firstly, request a token
term.Echo({ Foo : 'foo', Bar : 'bar' }, function(err, data) {
    fmt.msg('\ncalling echo - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});
