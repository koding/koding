'use strict';

var assert = require('assert');

var ses = require('../').load('ses');

ses.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);

try {
	ses.setRegion('us-east-1');
} catch (e) {
	assert.ok(e instanceof Error);
}

var callbacks = {
	request: false,
	requestWithoutQuery: false
};

var sesProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.ListVerifiedEmailAddressesResult.VerifiedEmailAddresses);
};

ses.request('ListVerifiedEmailAddresses', {}, function (err, res) {
	callbacks.request = true;
	sesProcessResponse(err, res);
});

ses.request('ListVerifiedEmailAddresses', function (err, res) {
	callbacks.requestWithoutQuery = true;
	sesProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
