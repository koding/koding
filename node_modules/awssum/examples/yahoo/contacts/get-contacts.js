var fmt = require('fmt');
var commander = require('commander');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var contactsService = awssum.load('yahoo/contacts');

var env            = process.env;
var consumerKey    = env.YAHOO_CONSUMER_KEY;
var consumerSecret = env.YAHOO_CONSUMER_SECRET;
var token          = env.YAHOO_TOKEN;
var tokenSecret    = env.YAHOO_TOKEN_SECRET;
// don't need the verifier
var yahooGuid = process.env.YAHOO_GUID;

var contacts = new contactsService.Contacts({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret,
    'yahooGuid'      : yahooGuid,
});

contacts.setToken(token);
contacts.setTokenSecret(tokenSecret);

fmt.field('ConsumerKey', contacts.consumerKey()     );
fmt.field('ConsumerSecret', contacts.consumerSecret() );
fmt.field('Token', contacts.token()          );
fmt.field('TokenSecret', contacts.tokenSecret()    );

// firstly, request a token
contacts.GetContacts(function(err, data) {
    fmt.msg('\ncalling getcontacts - expecting success');
    fmt.dump(err, 'Err');
    fmt.dump(data, 'Data');
});
