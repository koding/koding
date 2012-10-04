'use strict';

var assert = require('assert');

var rds = require('../').load('rds');

rds.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
rds.setRegion('us-east-1');

var callbacks = {
	request: false,
	requestWithoutQuery: false,
	requestWithQuery: false
};

var rdsProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.DescribeDBInstancesResult.DBInstances);
};

rds.request('DescribeDBInstances', {}, function (err, res) {
	callbacks.request = true;
	rdsProcessResponse(err, res);
});

rds.request('DescribeDBInstances', function (err, res) {
	callbacks.requestWithoutQuery = true;
	rdsProcessResponse(err, res);
});

rds.request('DescribeDBInstances', {MaxRecords: 20}, function (err, res) {
	callbacks.requestWithQuery = true;
	rdsProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
