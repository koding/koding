'use strict';

var assert = require('assert');
var ec2 = require('../').load('ec2');

ec2.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
ec2.setRegion('us-east-1');

var callbacks = {
	request: false,
	requestWithoutQuery: false,
	requestWithFilter: false
};

var ec2ProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.reservationSet);
};

ec2.request('DescribeInstances', {}, function (err, res) {
	callbacks.request = true;
	ec2ProcessResponse(err, res);
});

ec2.request('DescribeInstances', function (err, res) {
	callbacks.requestWithoutQuery = true;
	ec2ProcessResponse(err, res);
});

ec2.request('DescribeInstances', {'Filter.1.Name': 'architecture', 'Filter.1.Value.1': 'i386'}, function (err, res) {
	callbacks.requestWithFilter = true;
	ec2ProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
