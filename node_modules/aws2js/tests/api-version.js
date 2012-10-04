'use strict';

var assert = require('assert');
var ec2 = require('../').load('ec2');

ec2.setApiVersion('2010-01-01');
assert.deepEqual(ec2.getApiVersion(), '2010-01-01');

try {
	ec2.setApiVersion('foo');
	assert.ok(false);
} catch (err) {
	assert.ok(err instanceof Error);
	assert.deepEqual(err.message, 'Invalid version specification for client.setApiVersion().');
}
