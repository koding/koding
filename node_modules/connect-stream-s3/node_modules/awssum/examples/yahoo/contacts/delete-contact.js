var inspect = require('eyes').inspector({ maxLength : 65536 });
var commander = require('commander');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var contactsService = awssum.load('yahoo/contacts');

var env = process.env;
var consumerKey = process.env.YAHOO_CONSUMER_KEY;
var consumerSecret = process.env.YAHOO_CONSUMER_SECRET;
var token = process.env.YAHOO_TOKEN;
var tokenSecret = process.env.YAHOO_TOKEN_SECRET;
// don't need the verifier
var yahooGuid = process.env.YAHOO_GUID;

var contacts = new contactsService.Contacts({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret,
    'yahooGuid'      : yahooGuid,
});

contacts.setToken(token);
contacts.setTokenSecret(tokenSecret);

console.log( 'ConsumerKey    :', contacts.consumerKey()     );
console.log( 'ConsumerSecret :', contacts.consumerSecret() );
console.log( 'Token          :', contacts.token()          );
console.log( 'TokenSecret    :', contacts.tokenSecret()    );

// firstly, request a token
contacts.DeleteContact({ Cid : '7272' }, function(err, data) {
    console.log('\ncalling DeleteContact - expecting failure');
    inspect(err, 'Err');
    inspect(data, 'Data');
});
