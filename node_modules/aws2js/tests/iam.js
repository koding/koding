'use strict';

var assert = require('assert');
var iam = require('../').load('iam');

iam.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);

try {
	iam.setRegion('us-east-1');
} catch (e) {
	assert.ok(e instanceof Error);
}

var callbacks = {
	request: false,
	requestWithoutQuery: false
};

var iamProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.ListUsersResult.Users);
};

iam.request('ListUsers', {}, function (err, res) {
	callbacks.request = true;
	iamProcessResponse(err, res);
});

iam.request('ListUsers', function (err, res) {
	callbacks.requestWithoutQuery = true;
	iamProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
