var assert = require('assert');
var https = require('https');
var ec2 = require('../').load('ec2');

ec2.setMaxSockets(10);
assert.deepEqual(https.Agent.defaultMaxSockets, 10);

ec2.setMaxSockets(-10);
assert.deepEqual(https.Agent.defaultMaxSockets, 10);

ec2.setMaxSockets('foo');
assert.deepEqual(https.Agent.defaultMaxSockets, 5);

ec2.setMaxSockets({});
assert.deepEqual(https.Agent.defaultMaxSockets, 5);
