var inspect = require('eyes').inspector({ maxLength : 65536 });
var commander = require('commander');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var xeroService = awssum.load('xero/xero');

var env = process.env;
var consumerKey = process.env.XERO_CONSUMER_KEY;
var consumerSecret = process.env.XERO_CONSUMER_SECRET;
var token = process.env.XERO_TOKEN;
var tokenSecret = process.env.XERO_TOKEN_SECRET;
// don't need the verifier

var xero = new xeroService.Xero({
    'consumerKey'    : consumerKey,
    'consumerSecret' : consumerSecret
});

xero.setToken(token);
xero.setTokenSecret(tokenSecret);

console.log( 'ConsumerKey    :', xero.consumerKey()     );
console.log( 'ConsumerSecret :', xero.consumerSecret() );
console.log( 'Token          :', xero.token()          );
console.log( 'TokenSecret    :', xero.tokenSecret()    );

var data1 = {
    Contacts : [
        {
            Name : 'Berry Brew',
        }
    ]
};

var data2 = {
    Contacts : [
        {
            Name : 'Brew Berry',
        }
    ]
};

xero.CreateContacts(data1, function(err, data) {
    console.log('\nadding a contact for "Berry Brew" - expecting failure');
    inspect(err, 'Err');
    inspect(data, 'Data');
});

xero.CreateContacts(data2, function(err, data) {
    console.log('\nadding a contact for "Brew Berry" - expecting success');
    inspect(err, 'Err');
    inspect(data, 'Data');
});
