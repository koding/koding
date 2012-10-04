'use strict';

var assert = require('assert');
var sts = require('../').load('sts');

sts.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);

try {
	sts.setRegion('us-east-1');
} catch (e) {
	assert.ok(e instanceof Error);
}

var callbacks = {
	request: false,
	requestWithoutQuery: false
};

var stsProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.GetSessionTokenResult.Credentials);
};

sts.request('GetSessionToken', {}, function (err, res) {
	callbacks.request = true;
	stsProcessResponse(err, res);
});

sts.request('GetSessionToken', function (err, res) {
	callbacks.requestWithoutQuery = true;
	stsProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
