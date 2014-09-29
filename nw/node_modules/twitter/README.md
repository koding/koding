Twitter API client library for node.js
======================================

[node-twitter](https://github.com/desmondmorris/node-twitter) aims to provide a complete, asynchronous client library for the Twitter API, including the REST, search and streaming endpoints. It was inspired by, and uses some code from, [@technoweenie](https://github.com/technoweenie)'s [twitter-node](https://github.com/technoweenie/twitter-node).

## Requirements

You can install node-twitter and its dependencies with npm: `npm install twitter`.

- [node](http://nodejs.org/) v0.6+
- [node-oauth](https://github.com/ciaranj/node-oauth)
- [cookies](https://github.com/jed/cookies)

## Getting started

It's early days for node-twitter, so I'm going to assume a fair amount of knowledge for the moment. Better documentation to come as we head towards a stable release.

### Setup API (stable)

	var util = require('util'),
		twitter = require('twitter');
	var twit = new twitter({
		consumer_key: 'STATE YOUR NAME',
		consumer_secret: 'STATE YOUR NAME',
		access_token_key: 'STATE YOUR NAME',
		access_token_secret: 'STATE YOUR NAME'
	});

### Authenticate

The format of this depends somewhat on how your routing works, but it should be clear enough.

    app.get('/', twit.gatekeeper('/login'), routes.index);
    app.get('/login', routes.login);
    app.get('/twauth', twit.login());

You'll need to create the routes for index & login. On the login page, you'll want a link like:

    <a href="/twauth">Log in with Twitter</a>

### Basic OAuth-enticated GET/POST API (stable)

The convenience APIs aren't finished, but you can get started with the basics:

	twit.get('/statuses/show/27593302936.json', {include_entities:true}, function(data) {
		console.log(util.inspect(data));
	});

### REST API (unstable, may change)

Note that all functions may be chained:

	twit
		.verifyCredentials(function(data) {
			console.log(util.inspect(data));
		})
		.updateStatus('Test tweet from node-twitter/' + twitter.VERSION,
			function(data) {
				console.log(util.inspect(data));
			}
		);

### Search API (unstable, may change)

	twit.search('nodejs OR #node', function(data) {
		console.log(util.inspect(data));
	});

### Streaming API (stable)

The stream() callback receives a Stream-like EventEmitter:

	twit.stream('statuses/sample', function(stream) {
		stream.on('data', function(data) {
			console.log(util.inspect(data));
		});
	});

node-twitter also supports user, filter and site streams:

	twit.stream('user', {track:'nodejs'}, function(stream) {
		stream.on('data', function(data) {
			console.log(util.inspect(data));
		});
		// Disconnect stream after five seconds
		setTimeout(stream.destroy, 5000);
	});

new added events

this library now supports new added events which you can listen on.

`follow`
`favorite`
`unfavorite`
`block`
`unblock`
`list_created`
`list_destroyed`
`list_updated`
`list_member_added`
`list_member_removed`
`list_user_subscribed`
`list_user_unsubscribed`
`user_update`
