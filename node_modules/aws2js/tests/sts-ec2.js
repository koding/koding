'use strict';

var assert = require('assert');
var aws = require('../');
var sts = aws.load('sts', process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
var ec2 = aws.load('ec2');

var callbacks = {
	request: false,
	requestWithoutQuery: false,
	requestWithFilter: false
};

var ec2ProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.reservationSet);
};

sts.request('GetSessionToken', function (err, res) {
	assert.ifError(err);
	
	var credentials = res.GetSessionTokenResult.Credentials;
	ec2.setCredentials(credentials.AccessKeyId, credentials.SecretAccessKey, credentials.SessionToken);
	ec2.setRegion('us-east-1');
	
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
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
