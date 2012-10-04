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
var verifier       = env.TERM_VERIFIER;

var term = new termService.Term({
    'consumerKey' : consumerKey,
    'consumerSecret' : consumerSecret
});

term.setToken(token);
term.setTokenSecret(tokenSecret);

fmt.field('ConsumerKey', term.consumerKey()    );
fmt.field('ConsumerSecret', term.consumerSecret() );
fmt.field('Token', term.token()          );
fmt.field('TokenSecret', term.tokenSecret()    );

commander.prompt('Enter your verification code : ', function(verifier) {
    term.GetToken({ OAuthVerifier : verifier }, function(err, data) {
        fmt.msg("getting token - expecting success");
        fmt.dump(err, 'Error');
        fmt.dump(data, 'Data');
    });
});
