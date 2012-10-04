'use strict';

var assert = require('assert');

var emr = require('../').load('emr');

emr.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);

var callbacks = {
	request: false,
	requestWithoutQuery: false
};

var emrProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.DescribeJobFlowsResult.JobFlows);
};

emr.request('DescribeJobFlows', {}, function (err, res) {
	callbacks.request = true;
	emrProcessResponse(err, res);
});

emr.request('DescribeJobFlows', function (err, res) {
	callbacks.requestWithoutQuery = true;
	emrProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
