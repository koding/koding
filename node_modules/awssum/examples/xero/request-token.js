var fmt = require('fmt');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var xeroService = awssum.load('xero/xero');

var env            = process.env;
var consumerKey    = env.XERO_CONSUMER_KEY;
var consumerSecret = env.XERO_CONSUMER_SECRET;
// don't need the token, tokenSecret or verifier

var xero = new xeroService.Xero({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});


fmt.field('ConsumerKey', xero.consumerKey() );
fmt.field('ConsumerSecret', xero.consumerSecret() );

xero.RequestToken({ 'OAuthCallback' : 'oob' }, function(err, data) {
    fmt.msg("requesting token - expecting success");
    if ( err ) {
        fmt.dump(err, 'Error');
        process.exit();
    }

    fmt.dump(data, 'Data');
    fmt.msg( 'If you want to verify this token, visit: '
                 + xero.protocol() + '://' + xero.authorizeHost()
                 + xero.authorizePath()
                 + '?oauth_token=' + data.Body.oauth_token
               );
});
