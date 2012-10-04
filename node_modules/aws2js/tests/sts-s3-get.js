'use strict';

var assert = require('assert');
var aws = require('../');
var sts = aws.load('sts', process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
var s3 = aws.load('s3');

var callback = false;

sts.request('GetSessionToken', function (err, res) {
	var credentials = res.GetSessionTokenResult.Credentials;
	assert.ifError(err);
	
	s3.setCredentials(credentials.AccessKeyId, credentials.SecretAccessKey, credentials.SessionToken);
	
	s3.get('/', 'xml', function (err, res) {
		callback = true;
		assert.ifError(err);
		assert.ok(res.Buckets);
	});
});

process.on('exit', function () {
	assert.ok(callback);
});
