var fmt = require('fmt');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var termService = awssum.load('term/term');

var env            = process.env;
var consumerKey    = env.TERM_CONSUMER_KEY;
var consumerSecret = env.TERM_CONSUMER_SECRET;
// don't need the token, tokenSecret or verifier

var term = new termService.Term({
    'consumerKey' : consumerKey,
    'consumerSecret' : consumerSecret
});

fmt.field('ConsumerKey', term.consumerKey() );
fmt.field('ConsumerSecret', term.consumerSecret() );

term.RequestToken({ 'OAuthCallback' : 'oob' }, function(err, data) {
    fmt.msg("requesting token - expecting success");
    if ( err ) {
        fmt.dump(err, 'Error');
        process.exit();
    }

    fmt.dump(data, 'Data');
    fmt.msg( 'If you want to verify this token, visit: '
                 + term.protocol() + '://' + term.authorizeHost()
                 + term.authorizePath()
                 + '?oauth_token=' + data.Body.oauth_token
               );
});
