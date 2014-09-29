var	VERSION = '0.2.12',
	http = require('http'),
	querystring = require('querystring'),
	oauth = require('oauth'),
	Cookies = require('cookies'),
	Keygrip = require('keygrip'),
	streamparser = require('./parser');

function merge(defaults, options) {
	defaults = defaults || {};
	if (options && typeof options === 'object') {
		var keys = Object.keys(options);
		for (var i = 0, len = keys.length; i < len; i++) {
			var k = keys[i];
			if (options[k] !== undefined) defaults[k] = options[k];
		}
	}
	return defaults;
}


function Twitter(options) {
	if (!(this instanceof Twitter)) return new Twitter(options);

	var defaults = {
		consumer_key: null,
		consumer_secret: null,
		access_token_key: null,
		access_token_secret: null,

		headers: {
			'Accept': '*/*',
			'Connection': 'close',
			'User-Agent': 'node-twitter/' + VERSION
		},

		request_token_url: 'https://api.twitter.com/oauth/request_token',
		access_token_url: 'https://api.twitter.com/oauth/access_token',
		authenticate_url: 'https://api.twitter.com/oauth/authenticate',
		authorize_url: 'https://api.twitter.com/oauth/authorize',
		callback_url: null,

		rest_base: 'https://api.twitter.com/1.1',
		stream_base: 'https://stream.twitter.com/1.1',
		search_base: 'https://api.twitter.com/1.1/search',
		user_stream_base: 'https://userstream.twitter.com/1.1',
		site_stream_base: 'https://sitestream.twitter.com/1.1',
		filter_stream_base: 'https://stream.twitter.com/1.1/statuses',

		secure: false, // force use of https for login/gatekeeper
		cookie: 'twauth',
		cookie_options: {},
		cookie_secret: null
	};
	this.options = merge(defaults, options);

	this.keygrip = this.options.cookie_secret === null ? null :
		new Keygrip([this.options.cookie_secret]);

	this.oauth = new oauth.OAuth(
		this.options.request_token_url,
		this.options.access_token_url,
		this.options.consumer_key,
		this.options.consumer_secret,
		'1.0',
		this.options.callback_url,
		'HMAC-SHA1', null,
		this.options.headers
	);
}
Twitter.VERSION = VERSION;
module.exports = Twitter;


/*
 * GET
 */
Twitter.prototype.get = function(url, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	if ( typeof callback !== 'function' ) {
		throw "FAIL: INVALID CALLBACK.";
	}

	if (url.charAt(0) == '/')
		url = this.options.rest_base + url;

	url = params == null ? url : url + '?' + querystring.stringify(params);

	this.oauth.get(url,
		this.options.access_token_key,
		this.options.access_token_secret,
	function(error, data, response) {
		if (error) {
			var err = new Error('HTTP Error ' +
					error.statusCode + ': ' +
					http.STATUS_CODES[error.statusCode]);
			err.statusCode = error.statusCode;
			err.data = error.data;
			callback(err);
		} else {
			try {
				var json = JSON.parse(data);
				callback(json);
			} catch(err) {
				callback(err);
			}
		}
	});
	return this;
};


/*
 * POST
 */
Twitter.prototype.post = function(url, content, content_type, callback) {
	if (typeof content === 'function') {
		callback = content;
		content = null;
		content_type = null;
	} else if (typeof content_type === 'function') {
		callback = content_type;
		content_type = null;
	}

	if ( typeof callback !== 'function' ) {
		throw "FAIL: INVALID CALLBACK.";
	}

	if (url.charAt(0) == '/')
		url = this.options.rest_base + url;

	// Workaround: oauth + booleans == broken signatures
	if (content && typeof content === 'object') {
		Object.keys(content).forEach(function(e) {
			if ( typeof content[e] === 'boolean' )
				content[e] = content[e].toString();
		});
	}

	this.oauth.post(url,
		this.options.access_token_key,
		this.options.access_token_secret,
		content, content_type,
	function(error, data, response) {
		if (error) {
			var err = new Error('HTTP Error ' +
				  error.statusCode + ': ' +
				  http.STATUS_CODES[error.statusCode]);
			err.statusCode = error.statusCode;
			err.data = error.data;
			callback(err);
		} else {
			try {
				var json = JSON.parse(data);
				callback(json);
			} catch(err) {
				callback(err);
			}
		}
	});
	return this;
};


/*
 * SEARCH (not API stable!)
 */
Twitter.prototype.search = function(q, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	if ( typeof callback !== 'function' ) {
		throw "FAIL: INVALID CALLBACK.";
	}

	var url = this.options.search_base + '/tweets.json';
	params = merge(params, {q:q});
	this.get(url, params, callback);
	return this;
};


/*
 * STREAM
 */
Twitter.prototype.stream = function(method, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var stream_base = this.options.stream_base;

	// Stream type customisations
	if (method === 'user') {
		stream_base = this.options.user_stream_base;
		// Workaround for node-oauth vs. twitter commas-in-params bug
		if ( params && params.track && Array.isArray(params.track) ) {
			params.track = params.track.join(',');
		}

	} else if (method === 'site') {
		stream_base = this.options.site_stream_base;
		// Workaround for node-oauth vs. twitter double-encode-commas bug
		if ( params && params.follow && Array.isArray(params.follow) ) {
			params.follow = params.follow.join(',');
		}
	} else if (method === 'filter') {
		stream_base = this.options.filter_stream_base;
		// Workaround for node-oauth vs. twitter commas-in-params bug
		if ( params && params.track && Array.isArray(params.track) ) {
			params.track = params.track.join(',');
		}
	}


	var url = stream_base + '/' + escape(method) + '.json';

	var request = this.oauth.post(url,
		this.options.access_token_key,
		this.options.access_token_secret,
		params);

	var stream = new streamparser();
	stream.destroy = function() {
		// FIXME: should we emit end/close on explicit destroy?
		if ( typeof request.abort === 'function' )
			request.abort(); // node v0.4.0
		else
			request.socket.destroy();
	};

	request.on('response', function(response) {
		// FIXME: Somehow provide chunks of the response when the stream is connected
		// Pass HTTP response data to the parser, which raises events on the stream
		response.on('follow', function(chunk){
			stream.receive(chunk);
		});

		response.on('favorite', function(chunk){
			stream.receive(chunk);
		});

		response.on('unfavorite', function(chunk){
			stream.receive(chunk);
		});

		response.on('block', function(chunk){
			stream.receive(chunk);
		});

		response.on('unblock', function(chunk){
			stream.receive(chunk);
		});

		response.on('list_created', function(chunk){
			stream.receive(chunk);
		});

		response.on('list_destroyed', function(chunk){
			stream.receive(chunk);
		});

		response.on('list_updated', function(chunk){
			stream.receive(chunk);
		});

		response.on('list_member_added', function(chunk){
			stream.receive(chunk);
		});

		response.on('list_member_removed', function(chunk){
			stream.receive(chunk);
		});

		response.on('list_user_subscribed', function(chunk){
			stream.receive(chunk);
		});

		response.on('list_user_unsubscribed', function(chunk){
			stream.receive(chunk);
		});

		response.on('user_update', function(chunk){
			stream.receive(chunk);
		});

		response.on('data', function(chunk) {
			stream.receive(chunk);
		});

		response.on('error', function(error) {
			stream.emit('error', error);
		});

		response.on('end', function() {
			stream.emit('end', response);
		});
	});

	request.on('error', function(error) {
		stream.emit('error', error);
	});
	request.end();

	if ( typeof callback === 'function' ) callback(stream);
	return this;
};


/*
 * TWITTER "O"AUTHENTICATION UTILITIES, INCLUDING THE GREAT
 * CONNECT/STACK STYLE TWITTER "O"AUTHENTICATION MIDDLEWARE
 * and helpful utilities to retrieve the twauth cookie etc.
 */
Twitter.prototype.cookie = function(req) {
	// Fetch the cookie
	var cookies = new Cookies(req, null, this.keygrip);
	return this._readCookie(cookies);
};

Twitter.prototype.login = function(mount, success) {
	var self = this,
		url = require('url');

	// Save the mount point for use in gatekeeper
	this.options.login_mount = mount = mount || '/twauth';

	// Use secure cookie if forced to https and haven't configured otherwise
	if ( this.options.secure && !this.options.cookie_options.secure )
		this.options.cookie_options.secure = true;

	return function handle(req, res, next) {
		var path = url.parse(req.url, true);

		// We only care about requests against the exact mount point
		if ( path.pathname !== mount ) return next();

		// Set the oauth_callback based on this request if we don't have it
		if ( !self.oauth._authorize_callback ) {
			// have to get the entire url because this is an external callback
			// but it's only done once...
			var scheme = (req.socket.secure || self.options.secure) ? 'https://' : 'http://';
			path = url.parse(scheme + req.headers.host + req.url, true);
			self.oauth._authorize_callback = path.href;
		}

		// Fetch the cookie
		var cookies = new Cookies(req, res, self.keygrip);
		var twauth = self._readCookie(cookies);

		// We have a winner, but they're in the wrong place
		if ( twauth && twauth.user_id && twauth.access_token_secret ) {
			res.status(302).redirect( success || '/');
			res.end();
			return;

		// Returning from Twitter with oauth_token
		} else if ( path.query && path.query.oauth_token && path.query.oauth_verifier && twauth && twauth.oauth_token_secret ) {
			self.oauth.getOAuthAccessToken(
				path.query.oauth_token,
				twauth.oauth_token_secret,
				path.query.oauth_verifier,
			function(error, access_token_key, access_token_secret, params) {
				// FIXME: if we didn't get these, explode
				var user_id = (params && params.user_id) || null,
					screen_name = (params && params.screen_name) || null;

				if ( error ) {
					// FIXME: do something more intelligent
					return next(500);
				} else {
					// store access token
					self.options.access_token_key = twauth.access_token_key;
 					self.options.access_token_secret = twauth.access_token_secret;
					cookies.set(self.options.cookie, JSON.stringify({
						user_id: user_id,
						screen_name: screen_name,
						access_token_key: access_token_key,
						access_token_secret: access_token_secret
					}), self.options.cookie_options);
					res.writeHead(302, {'Location': success || '/'});
					res.end();
					return;
				}
			});

		// Begin OAuth transaction if we have no cookie or access_token_secret
		} else if ( !(twauth && twauth.access_token_secret) ) {
			self.oauth.getOAuthRequestToken(
			function(error, oauth_token, oauth_token_secret, oauth_authorize_url, params) {
				if ( error ) {
					// FIXME: do something more intelligent
					return next(500);
				} else {
					cookies.set(self.options.cookie, JSON.stringify({
						oauth_token: oauth_token,
						oauth_token_secret: oauth_token_secret
					}), self.options.cookie_options);
					res.writeHead(302, {
						'Location': self.options.authorize_url + '?' +
							  querystring.stringify({oauth_token: oauth_token})
					});
					res.end();
					return;
				}
			});

		// Broken cookie, clear it and return to originating page
		// FIXME: this is dumb
		} else {
			cookies.set(self.options.cookie, null, self.options.cookie_options);
			res.writeHead(302, {'Location': mount});
			res.end();
			return;
		}
	};
};

Twitter.prototype.gatekeeper = function(options) {
	var self = this,
		mount = this.options.login_mount || '/twauth',
        defaults = {
            failureRedirect: null
        };
    options = merge(defaults, options);

	return function(req, res, next) {
		var twauth = self.cookie(req);

		// We have a winner
		if ( twauth && twauth.user_id && twauth.access_token_secret ) {
			self.options.access_token_key = twauth.access_token_key;
 			self.options.access_token_secret = twauth.access_token_secret;
			return next();
		}

    if (options.failureRedirect) {
        res.redirect(options.failureRedirect);
    } else {
        res.writeHead(401, {}); // {} for bug in stack
        res.end([
            '<html><head>',
            '<meta http-equiv="refresh" content="1;url=' + mount + '">',
            '</head><body>',
            '<h1>Twitter authentication required.</h1>',
            '</body></html>'
        ].join(''));
    }
	};
};


/*
 * CONVENIENCE FUNCTIONS (not API stable!)
 */

// Timeline resources

Twitter.prototype.getHomeTimeline = function(params, callback) {
	var url = '/statuses/home_timeline.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getMentions = function(params, callback) {
	var url = '/statuses/mentions.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getRetweetedByMe = function(params, callback) {
	var url = '/statuses/retweeted_by_me.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getRetweetedToMe = function(params, callback) {
	var url = '/statuses/retweeted_to_me.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getRetweetsOfMe = function(params, callback) {
	var url = '/statuses/retweets_of_me.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getUserTimeline = function(params, callback) {
	var url = '/statuses/user_timeline.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getRetweetedToUser = function(params, callback) {
	var url = '/statuses/retweeted_to_user.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getRetweetedByUser = function(params, callback) {
	var url = '/statuses/retweeted_by_user.json';
	this.get(url, params, callback);
	return this;
};

// Tweets resources

Twitter.prototype.showStatus = function(id, callback) {
	var url = '/statuses/show/' + escape(id) + '.json';
	this.get(url, null, callback);
	return this;
};

Twitter.prototype.getStatus = Twitter.prototype.showStatus;

Twitter.prototype.updateStatus = function(text, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var url = '/statuses/update.json';
	var defaults = {
		status: text,
		include_entities: 1
	};
	params = merge(defaults, params);
	this.post(url, params, null, callback);
	return this;
};

Twitter.prototype.destroyStatus = function(id, callback) {
	var url = '/statuses/destroy/' + escape(id) + '.json';
	this.post(url, null, null, callback);
	return this;
};

Twitter.prototype.deleteStatus = Twitter.prototype.destroyStatus;

Twitter.prototype.retweetStatus = function(id, callback) {
	var url = '/statuses/retweet/' + escape(id) + '.json';
	this.post(url, null, null, callback);
	return this;
};

Twitter.prototype.getRetweets = function(id, params, callback) {
	var url = '/statuses/retweets/' + escape(id) + '.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getRetweetedBy = function(id, params, callback) {
	var url = '/statuses/' + escape(id) + '/retweeted_by.json';
	this.post(url, params, null, callback);
	return this;
};

Twitter.prototype.getRetweetedByIds = function(id, params, callback) {
	var url = '/statuses/' + escape(id) + '/retweeted_by/ids.json';
	this.post(url, params, null, callback);
	return this;
};

// User resources

Twitter.prototype.showUser = function(id, callback) {
	//  NOTE: params with commas b0rk between node-oauth and twitter
	//        https://github.com/ciaranj/node-oauth/issues/7
	var url = '/users/show.json';

	var params = {};

	if (typeof id === 'object' && id !== null) {
		params = id;
	}
	else if (typeof id === 'string')
		params.screen_name = id;
	else
		params.user_id = id;

	this.get(url, params, callback);
	return this;
}
Twitter.prototype.lookupUser = Twitter.prototype.showUser;

Twitter.prototype.lookupUsers = function(ids, callback) {
  var url = '/users/lookup.json';

  var params = {};

  params.user_id = JSON.stringify(ids);

  this.get(url, params, callback);
  return this;
}

Twitter.prototype.searchUser = function(q, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var url = '/users/search.json';
	params = merge(params, {q:q});
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.searchUsers = Twitter.prototype.searchUser;

// FIXME: users/suggestions**

Twitter.prototype.userProfileImage = function(id, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	} else if (typeof params === 'string') {
		params = { size: params };
	}

	var url = '/users/profile_image/' + escape(id) + '.json?' + querystring.stringify(params);

	// Do our own request, so we can return the 302 location header
	var request = this.oauth.get(this.options.rest_base + url,
		this.options.access_token_key,
		this.options.access_token_secret);
	request.on('response', function(response) {
		// return the location or an HTTP error
		callback(response.headers.location || new Error('HTTP Error ' +
			  response.statusCode + ': ' +
			  http.STATUS_CODES[response.statusCode]));
	});
	request.end();

	return this;
};

// FIXME: statuses/friends, statuses/followers

// Trends resources

Twitter.prototype.getTrends = function(callback) {
	var url = '/trends.json';
	this.get(url, null, callback);
	return this;
};

Twitter.prototype.getCurrentTrends = function(params, callback) {
	var url = '/trends/current.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getDailyTrends = function(params, callback) {
	var url = '/trends/daily.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getWeeklyTrends = function(params, callback) {
	var url = '/trends/weekly.json';
	this.get(url, params, callback);
	return this;
};

// Local Trends resources

// List resources

Twitter.prototype.getLists = function(id, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var defaults = {key:'lists'};

	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		defaults.screen_name = id;
	else
		defaults.user_id = id;

	params = merge(defaults, params);
console.log(params);
	var url = '/lists.json';
	this._getUsingCursor(url, params, callback);
	return this;
};

Twitter.prototype.getListMemberships = function(id, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var defaults = {key:'lists'};

	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		defaults.screen_name = id;
	else
		defaults.user_id = id;
	params = merge(defaults, params);

	var url = '/lists/memberships.json';
	this._getUsingCursor(url, params, callback);
	return this;
};

Twitter.prototype.getListSubscriptions = function(id, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var defaults = {key:'lists'};
	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		defaults.screen_name = id;
	else
		defaults.user_id = id;
	params = merge(defaults, params);

	var url = '/lists/subscriptions.json';
	this._getUsingCursor(url, params, callback);
	return this;
};

// FIXME: Uses deprecated Twitter lists API
Twitter.prototype.showList = function(screen_name, list_id, callback) {
	var url = '/' + escape(screen_name) + '/lists/' + escape(list_id) + '.json';
	this.get(url, null, callback);
	return this;
};

// FIXME: Uses deprecated Twitter lists API
Twitter.prototype.getListTimeline = function(screen_name, list_id, params, callback) {
	var url = '/' + escape(screen_name) + '/lists/' + escape(list_id) + '/statuses.json';
	this.get(url, params, callback);
	return this;
};
Twitter.prototype.showListStatuses = Twitter.prototype.getListTimeline;

// FIXME: Uses deprecated Twitter lists API
Twitter.prototype.createList = function(screen_name, list_name, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var url = '/' + escape(screen_name) + '/lists.json';
	params = merge(params, {name:list_name});
	this.post(url, params, null, callback);
	return this;
};

// FIXME: Uses deprecated Twitter lists API
Twitter.prototype.updateList = function(screen_name, list_id, params, callback) {
	var url = '/' + escape(screen_name) + '/lists/' + escape(list_id) + '.json';
	this.post(url, params, null, callback);
	return this;
};

// FIXME: Uses deprecated Twitter lists API
Twitter.prototype.deleteList = function(screen_name, list_id, callback) {
	var url = '/' + escape(screen_name) + '/lists/' + escape(list_id) + '.json?_method=DELETE';
	this.post(url, null, callback);
	return this;
};

Twitter.prototype.destroyList = Twitter.prototype.deleteList;

// List Members resources

// FIXME: Uses deprecated Twitter lists API
Twitter.prototype.getListMembers = function(screen_name, list_id, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var url = '/' + escape(screen_name) + '/' + escape(list_id) + '/members.json';
	params = merge(params, {key:'users'});
	this._getUsingCursor(url, params, callback);
	return this;
};

// FIXME: the rest of list members

// List Subscribers resources

// FIXME: Uses deprecated Twitter lists API
Twitter.prototype.getListSubscribers = function(screen_name, list_id, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var url = '/' + escape(screen_name) + '/' + escape(list_id) + '/subscribers.json';
	params = merge(params, {key:'users'});
	this._getUsingCursor(url, params, callback);
	return this;
};

// FIXME: the rest of list subscribers

// Direct Messages resources

Twitter.prototype.getDirectMessages = function(params, callback) {
	var url = '/direct_messages.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getDirectMessagesSent = function(params, callback) {
	var url = '/direct_messages/sent.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getSentDirectMessages = Twitter.prototype.getDirectMessagesSent;

Twitter.prototype.newDirectMessage = function(id, text, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var defaults = {
		text: text,
		include_entities: 1
	};
	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		defaults.screen_name = id;
	else
		defaults.user_id = id;
	params = merge(defaults, params);

	var url = '/direct_messages/new.json';
	this.post(url, params, null, callback);
	return this;
};

Twitter.prototype.updateDirectMessage = Twitter.prototype.sendDirectMessage = Twitter.prototype.newDirectMessage;

Twitter.prototype.destroyDirectMessage = function(id, callback) {
	var url = '/direct_messages/destroy/' + escape(id) + '.json?_method=DELETE';
	this.post(url, null, callback);
	return this;
};

Twitter.prototype.deleteDirectMessage = Twitter.prototype.destroyDirectMessage;

// Friendship resources

Twitter.prototype.createFriendship = function(id, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = null;
	}

	var defaults = {
		include_entities: 1
	};
	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		defaults.screen_name = id;
	else
		defaults.user_id = id;
	params = merge(defaults, params);

	var url = '/friendships/create.json';
	this.post(url, params, null, callback);
	return this;
};

Twitter.prototype.destroyFriendship = function(id, callback) {
	if (typeof id === 'function') {
		callback = id;
		id = null;
	}

	var params = {
		include_entities: 1
	};
	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		params.screen_name = id;
	else
		params.user_id = id;

	var url = '/friendships/destroy.json?_method=DELETE';
	this.post(url, params, null, callback);
	return this;
};

Twitter.prototype.deleteFriendship = Twitter.prototype.destroyFriendship;

// Only exposing friendships/show instead of friendships/exist

Twitter.prototype.showFriendship = function(source, target, callback) {
	var params = {};

	if (typeof source === 'object') {
		for(var source_property in source) {
			params[source_property] = source[source_property];
		}
	}
	else if (typeof source === 'string')
		params.source_screen_name = source;
	else
		params.source_id = source;

	if (typeof target === 'object') {
		for(var target_property in target) {
			params[target_property] = target[target_property];
		}
	}
	else if (typeof target === 'string')
		params.target_screen_name = target;
	else
		params.target_id = target;

	var url = '/friendships/show.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.incomingFriendship = function(callback) {
	var url = '/friendships/incoming.json';
	this._getUsingCursor(url, {key:'ids'}, callback);
	return this;
};

Twitter.prototype.incomingFriendships = Twitter.prototype.incomingFriendship;

Twitter.prototype.outgoingFriendship = function(callback) {
	var url = '/friendships/outgoing.json';
	this._getUsingCursor(url, {key:'ids'}, callback);
	return this;
};

Twitter.prototype.outgoingFriendships = Twitter.prototype.outgoingFriendship;

// Friends and Followers resources

Twitter.prototype.getFriendsIds = function(id, callback) {
	if (typeof id === 'function') {
		callback = id;
		id = null;
	}
	var params = {};
	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		params.screen_name = id;
	else if (typeof id === 'number')
		params.user_id = id;

	params.key = 'ids';

	var url = '/friends/ids.json';
	this._getUsingCursor(url, params, callback);
	return this;
};

Twitter.prototype.getFollowersIds = function(id, callback) {
	if (typeof id === 'function') {
		callback = id;
		id = null;
	}

	var params = {};

	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		params.screen_name = id;
	else if (typeof id === 'number')
		params.user_id = id;

	params.key = 'ids';

	var url = '/followers/ids.json';
	this._getUsingCursor(url, params, callback);
	return this;
};

// Account resources

Twitter.prototype.verifyCredentials = function(callback) {
	var url = '/account/verify_credentials.json';
	this.get(url, null, callback);
	return this;
};

Twitter.prototype.rateLimitStatus = function(callback) {
	var url = '/application/rate_limit_status.json';
	this.get(url, null, callback);
	return this;
};

Twitter.prototype.updateProfile = function(params, callback) {
	// params: name, url, location, description
	var defaults = {
		include_entities: 1
	};
	params = merge(defaults, params);

	var url = '/account/update_profile.json';
	this.post(url, params, null, callback);
	return this;
};

// FIXME: Account resources section not complete

// Favorites resources

Twitter.prototype.getFavorites = function(params, callback) {
	var url = '/favorites/list.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.createFavorite = function(params, callback) {
	var url = '/favorites/create.json';
	this.post(url, params, null, callback);
	return this;
};

Twitter.prototype.favoriteStatus = Twitter.prototype.createFavorite;

Twitter.prototype.destroyFavorite = function(id, params, callback) {
	var url = '/favorites/destroy.json';

    if(typeof params === 'function') {
        callback = params;
        params = null;
    }

    var defaults = {};

    if(typeof id === 'object') {
        params = id;
    }
    else
        defaults.id = id;

    params = merge(defaults, params);

	this.post(url, params, null, callback);
	return this;
};

Twitter.prototype.deleteFavorite = Twitter.prototype.destroyFavorite;

// Notification resources

// Block resources

Twitter.prototype.createBlock = function(id, callback) {
	var url = '/blocks/create.json';

	var params = {};
	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		params.screen_name = id;
	else
		params.user_id = id;

	this.post(url, params, null, callback);
	return this;
};

Twitter.prototype.blockUser = Twitter.prototype.createBlock;

Twitter.prototype.destroyBlock = function(id, callback) {
	var url = '/blocks/destroy.json';

	var params = {};
	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		params.screen_name = id;
	else
		params.user_id = id;

	this.post(url, params, null, callback);
	return this;
};

Twitter.prototype.unblockUser = Twitter.prototype.destroyBlock;

Twitter.prototype.blockExists = function(id, callback) {
	var url = '/blocks/exists.json';

	var params = {};
	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		params.screen_name = id;
	else
		params.user_id = id;

	this.get(url, params, null, callback);
	return this;
};

Twitter.prototype.isBlocked = Twitter.prototype.blockExists;

// FIXME: blocking section not complete (blocks/blocking + blocks/blocking/ids)

// Spam Reporting resources

Twitter.prototype.reportSpam = function(id, callback) {
	var url = '/report_spam.json';

	var params = {};
	if (typeof id === 'object') {
		params = id;
	}
	else if (typeof id === 'string')
		params.screen_name = id;
	else
		params.user_id = id;

	this.post(url, params, null, callback);
	return this;
};

// Saved Searches resources

Twitter.prototype.savedSearches = function(callback) {
	var url = '/saved_searches.json';
	this.get(url, null, callback);
	return this;
};

Twitter.prototype.showSavedSearch = function(id, callback) {
	var url = '/saved_searches/' + escape(id) + '.json';
	this.get(url, null, callback);
	return this;
};

Twitter.prototype.createSavedSearch = function(query, callback) {
	var url = '/saved_searches/create.json';
	this.post(url, {query: query}, null, callback);
	return this;
};
Twitter.prototype.newSavedSearch =
	Twitter.prototype.createSavedSearch;

Twitter.prototype.destroySavedSearch = function(id, callback) {
	var url = '/saved_searches/destroy/' + escape(id) + '.json?_method=DELETE';
	this.post(url, null, null, callback);
	return this;
};
Twitter.prototype.deleteSavedSearch =
	Twitter.prototype.destroySavedSearch;

// OAuth resources

// Geo resources

Twitter.prototype.geoSearch = function(params, callback) {
	var url = '/geo/search.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.geoSimilarPlaces = function(lat, lng, name, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = {};
	} else if (typeof params !== 'object') {
		params = {};
	}

	if (typeof lat !== 'number' || typeof lng !== 'number' || !name) {
		callback(new Error('FAIL: You must specify latitude, longitude (as numbers) and name.'));
	}

	var url = '/geo/similar_places.json';
	params.lat = lat;
	params.long = lng;
	params.name = name;
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.geoReverseGeocode = function(lat, lng, params, callback) {
	if (typeof params === 'function') {
		callback = params;
		params = {};
	} else if (typeof params !== 'object') {
		params = {};
	}

	if (typeof lat !== 'number' || typeof lng !== 'number') {
		callback(new Error('FAIL: You must specify latitude and longitude as numbers.'));
	}

	var url = '/geo/reverse_geocode.json';
	params.lat = lat;
	params.long = lng;
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.geoGetPlace = function(place_id, callback) {
	var url = '/geo/id/' + escape(place_id) + '.json';
	this.get(url, callback);
	return this;
};

// Legal resources

// Help resources

// Streamed Tweets resources

// Search resources

// Deprecated resources

Twitter.prototype.getPublicTimeline = function(params, callback) {
	var url = '/statuses/public_timeline.json';
	this.get(url, params, callback);
	return this;
};

Twitter.prototype.getFriendsTimeline = function(params, callback) {
	var url = '/statuses/friends_timeline.json';
	this.get(url, params, callback);
	return this;
};


/*
 * INTERNAL UTILITY FUNCTIONS
 */

Twitter.prototype._getUsingCursor = function(url, params, callback) {
	var key,
	  result = [],
	  self = this;

	params = params || {};
	key = params.key || null;

	// if we don't have a key to fetch, we're screwed
	if (!key)
		callback(new Error('FAIL: Results key must be provided to _getUsingCursor().'));
	delete params.key;

	// kick off the first request, using cursor -1
	params = merge(params, {cursor:-1});
	this.get(url, params, fetch);

	function fetch(data) {
		// FIXME: what if data[key] is not a list?
		if (data[key]) result = result.concat(data[key]);

		if (data.next_cursor_str === '0') {
			callback(result);
		} else {
			params.cursor = data.next_cursor_str;
			self.get(url, params, fetch);
		}
	}

	return this;
};

Twitter.prototype._readCookie = function(cookies) {
	// parse the auth cookie
	try {
		return JSON.parse(cookies.get(this.options.cookie));
	} catch (error) {
		return null;
	}
};
