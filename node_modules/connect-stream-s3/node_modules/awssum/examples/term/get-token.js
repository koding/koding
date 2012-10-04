var inspect = require('eyes').inspector();
var commander = require('commander');
var awssum = require('awssum');
var oauth = awssum.load('oauth');
var termService = awssum.load('term/term');

var env = process.env;
var consumerKey = process.env.TERM_CONSUMER_KEY;
var consumerSecret = process.env.TERM_CONSUMER_SECRET;
var token = process.env.TERM_TOKEN;
var tokenSecret = process.env.TERM_TOKEN_SECRET;
var verifier = process.env.TERM_VERIFIER;

var term = new termService.Term({
    'consumerKey' : consumerKey,
    'consumerSecret' : consumerSecret
});

term.setToken(token);
term.setTokenSecret(tokenSecret);

console.log( 'ConsumerKey    :', term.consumerKey()    );
console.log( 'ConsumerSecret :', term.consumerSecret() );
console.log( 'Token          :', term.token()          );
console.log( 'TokenSecret    :', term.tokenSecret()    );

commander.prompt('Enter your verification code : ', function(verifier) {
    term.GetToken({ OAuthVerifier : verifier }, function(err, data) {
        console.log("\ngetting token - expecting success");
        inspect(err, 'Error');
        inspect(data, 'Data');
    });
});
