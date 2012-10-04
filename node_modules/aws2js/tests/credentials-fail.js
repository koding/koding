'use strict';

var ec2 = require('../').load('ec2');
var assert = require('assert');

try {
	ec2.request('DescribeInstances');
} catch (err) {
	assert.ok(err instanceof Error);
	assert.deepEqual(err.message, 'You must set the AWS credentials: accessKeyId + secretAccessKey');
}
