'use strict';

var assert = require('assert');

var sqs = require('../').load('sqs');

sqs.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
sqs.setRegion('us-east-1');

var callbacks = {
	request: false,
	requestWithoutQuery: false
};

var sqsProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.ListQueuesResult.QueueUrl);
};

sqs.request('ListQueues', {}, function (err, res) {
	callbacks.request = true;
	sqsProcessResponse(err, res);
});

sqs.request('ListQueues', function (err, res) {
	callbacks.requestWithoutQuery = true;
	sqsProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
