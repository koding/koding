'use strict';

var assert = require('assert');
var aws = require('../');
var sts = aws.load('sts', process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
var sns = aws.load('sns');

var callbacks = {
	request: false,
	requestWithoutQuery: false
};

var snsProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.ListSubscriptionsResult.Subscriptions);
};

sts.request('GetSessionToken', function (err, res) {
	assert.ifError(err);
	
	var credentials = res.GetSessionTokenResult.Credentials;
	sns.setCredentials(credentials.AccessKeyId, credentials.SecretAccessKey, credentials.SessionToken);
	sns.setRegion('us-east-1');
	
	sns.request('ListSubscriptions', {}, function (err, res) {
		callbacks.request = true;
		snsProcessResponse(err, res);
	});
	
	sns.request('ListSubscriptions', function (err, res) {
		callbacks.requestWithoutQuery = true;
		snsProcessResponse(err, res);
	});
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
