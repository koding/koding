var fmt = require('fmt');
var base = require("rackspacecloud/base");
var authenticationService = require("rackspacecloud/authentication");

var env      = process.env;
var username = env.RACKSPACECLOUD_USERNAME;
var apiKey   = env.RACKSPACECLOUD_API_KEY;
var region   = env.RACKSPACECLOUD_REGION;

fmt.msg(username, apiKey, region);

var authentication = new authenticationService.Authentication(username, apiKey, region);

fmt.field('Region', authentication.region() );
fmt.field('EndPoint', authentication.host() );
fmt.field('Username', authentication.username() );
fmt.field('ApiKey', authentication.apiKey() );

authentication.getAuthToken({}, function(err, data) {
    fmt.msg("getting a token - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
