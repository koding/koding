var inspect = require('eyes').inspector();
var base = require("rackspacecloud/base");
var authenticationService = require("rackspacecloud/authentication");

var env = process.env;
var username = process.env.RACKSPACECLOUD_USERNAME;
var apiKey = process.env.RACKSPACECLOUD_API_KEY;
var region = process.env.RACKSPACECLOUD_REGION;

console.log(username, apiKey, region);

var authentication = new authenticationService.Authentication(username, apiKey, region);

console.log( 'Region :', authentication.region() );
console.log( 'EndPoint :',  authentication.host() );
console.log( 'Username :', authentication.username() );
console.log( 'ApiKey :', authentication.apiKey() );

authentication.getAuthToken({}, function(err, data) {
    console.log("\ngetting a token - expecting success");
    inspect(err, 'Error');
    inspect(data, 'Data');
});
