'use strict';

var assert = require('assert');
var cloudwatch = require('../').load('cloudwatch');

cloudwatch.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
cloudwatch.setRegion('us-east-1');

var callbacks = {
	request: false,
	requestWithoutQuery: false
};

var cloudwatchProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.DescribeAlarmsResult.MetricAlarms);
};

cloudwatch.request('DescribeAlarms', {}, function (err, res) {
	callbacks.request = true;
	cloudwatchProcessResponse(err, res);
});

cloudwatch.request('DescribeAlarms', function (err, res) {
	callbacks.requestWithoutQuery = true;
	cloudwatchProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
