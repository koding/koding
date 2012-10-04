'use strict';

var assert = require('assert');
var autoscaling = require('../').load('autoscaling');

autoscaling.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
autoscaling.setRegion('us-east-1');

var callbacks = {
	request: false,
	requestWithoutQuery: false
};

var autoscalingProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.DescribeScalingActivitiesResult.Activities);
};

autoscaling.request('DescribeScalingActivities', {}, function (err, res) {
	callbacks.request = true;
	autoscalingProcessResponse(err, res);
});

autoscaling.request('DescribeScalingActivities', function (err, res) {
	callbacks.requestWithoutQuery = true;
	autoscalingProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
