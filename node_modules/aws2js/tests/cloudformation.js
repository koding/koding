'use strict';

var assert = require('assert');

var cloudformation = require('../').load('cloudformation');

cloudformation.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
cloudformation.setRegion('us-east-1');

var callbacks = {
	request: false,
	requestWithoutQuery: false
};

var cloudformationProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.DescribeStacksResult.Stacks);
};

cloudformation.request('DescribeStacks', {}, function (err, res) {
	callbacks.request = true;
	cloudformationProcessResponse(err, res);
});

cloudformation.request('DescribeStacks', function (err, res) {
	callbacks.requestWithoutQuery = true;
	cloudformationProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
