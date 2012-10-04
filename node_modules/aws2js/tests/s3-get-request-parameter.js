'use strict';

var assert = require('assert');
var s3 = require('../').load('s3');

var callback = false;

s3.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
s3.setBucket(process.env.AWS2JS_S3_BUCKET);

s3.get('/', {'max-keys': 10}, 'xml', function (err, res) {
	callback = true;
	assert.ifError(err);
	assert.deepEqual(res.Name, process.env.AWS2JS_S3_BUCKET);
	assert.equal(res.MaxKeys, 10);
});

process.on('exit', function () {
	assert.ok(callback);
});
