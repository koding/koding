var fmt = require('fmt');
var commander = require('commander');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var xeroService = awssum.load('xero/xero');

var env            = process.env;
var consumerKey    = env.XERO_CONSUMER_KEY;
var consumerSecret = env.XERO_CONSUMER_SECRET;
var token          = env.XERO_TOKEN;
var tokenSecret    = env.XERO_TOKEN_SECRET;
// don't need the verifier

var xero = new xeroService.Xero({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});

xero.setToken(token);
xero.setTokenSecret(tokenSecret);

fmt.field('ConsumerKey', xero.consumerKey()     );
fmt.field('ConsumerSecret', xero.consumerSecret() );
fmt.field('Token', xero.token()          );
fmt.field('TokenSecret', xero.tokenSecret()    );

xero.GetContacts({ 'Where' : 'Name="Berry Brew"' }, function(err, data) {
    fmt.msg('\nget contacts where Name="Berry Brew" - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});
