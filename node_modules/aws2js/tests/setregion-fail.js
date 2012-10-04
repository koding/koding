var ec2 = require('../').load('ec2');
var assert = require('assert');

try {
	ec2.setRegion('this-does-not-exist');
	assert.ok(false);
} catch (err) {
	assert.ok(err instanceof Error);
	assert.deepEqual(err.message, 'Invalid region: this-does-not-exist');
}
