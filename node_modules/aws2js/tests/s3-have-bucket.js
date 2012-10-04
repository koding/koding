'use strict';

var assert = require('assert');
var s3 = require('../').load('s3');
var callback = false;

assert.ok(process.env.AWS2JS_S3_BUCKET !== undefined);

s3.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
s3.setBucket(process.env.AWS2JS_S3_BUCKET);

s3.head('/', function (err, res) {
	callback = true;
	assert.ifError(err);
	assert.deepEqual(res.server, 'AmazonS3');
});

process.on('exit', function () {
	assert.ok(callback);
});
