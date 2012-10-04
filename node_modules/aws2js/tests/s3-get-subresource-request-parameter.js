'use strict';

var assert = require('assert');
var s3 = require('../').load('s3');

var callbacks = {
	query: false,
	path: false,
	queryOnly: false
};

s3.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
s3.setBucket(process.env.AWS2JS_S3_BUCKET);

var s3ProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.deepEqual(res.Bucket, process.env.AWS2JS_S3_BUCKET);
	assert.equal(res.MaxUploads, 1);
};

s3.get('?uploads', {'max-uploads': 1}, 'xml', function (err, res) {
	callbacks.query = true;
	s3ProcessResponse(err, res);
});


s3.get('?uploads&max-uploads=1', 'xml', function (err, res) {
	callbacks.path = true;
	s3ProcessResponse(err, res);
});

s3.get('/', {uploads: null, 'max-uploads': 1}, 'xml', function (err, res) {
	callbacks.queryOnly = true;
	s3ProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
