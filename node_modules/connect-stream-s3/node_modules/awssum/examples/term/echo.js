var inspect = require('eyes').inspector({ maxLength : 65536 });
var commander = require('commander');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var termService = awssum.load('term/term');

var env = process.env;
var consumerKey = process.env.TERM_CONSUMER_KEY;
var consumerSecret = process.env.TERM_CONSUMER_SECRET;
var token = process.env.TERM_TOKEN;
var tokenSecret = process.env.TERM_TOKEN_SECRET;
// don't need the verifier

var term = new termService.Term({
    'consumerKey' : consumerKey,
    'consumerSecret' : consumerSecret
});

term.setToken(token);
term.setTokenSecret(tokenSecret);

console.log( 'ConsumerKey    :', term.consumerKey()     );
console.log( 'ConsumerSecret :', term.consumerSecret() );
console.log( 'Token          :', term.token()          );
console.log( 'TokenSecret    :', term.tokenSecret()    );

// firstly, request a token
term.Echo({ Foo : 'foo', Bar : 'bar' }, function(err, data) {
    console.log('\ncalling echo - expecting success');
    inspect(err, 'Err');
    inspect(data, 'Data');
});
