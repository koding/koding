'use strict';

var assert = require('assert');

try {
	var ec2 = require('../').load('ec3');
	assert.ok(false);
} catch (err) {
	assert.ok(err instanceof Error);
	assert.deepEqual(err.message, 'Invalid AWS client');
}
