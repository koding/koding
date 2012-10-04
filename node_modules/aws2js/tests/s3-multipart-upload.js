'use strict';

var cp = require('child_process');
var assert = require('assert');
var crypto = require('crypto');
var fs = require('fs');
var s3 = require('../').load('s3');

s3.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
s3.setBucket(process.env.AWS2JS_S3_BUCKET);

cp.execFile('../tools/createtemp.sh', function (err, res) {
	assert.ifError(err);
	var tempMd5 = res.replace(/\s/g, '');
	s3.putFileMultipart('10M.tmp', './10M.tmp', false, {}, 5242880, function (err, res) {
		assert.ifError(err);
		s3.get('10M.tmp', {file: './10M.tmp'}, function (err, res) {
			assert.ifError(err);
			var md5 = crypto.createHash('md5');
			var rs = fs.ReadStream('./10M.tmp');
			rs.on('data', function (data) {
				md5.update(data);
			});
			rs.on('end', function () {
				var dlMd5 = md5.digest('hex');
				assert.deepEqual(tempMd5, dlMd5);
				fs.unlink('./10M.tmp', function (err) {
					assert.ifError(err);
					s3.del('10M.tmp', function (err, res) {
						assert.ifError(err);
					});
				});
			});
			rs.on('error', function (err) {
				assert.ifError(err);
			});
		});
	});
});

var caught = false;
process.on('uncaughtException', function (err) {
	fs.unlink('10M.tmp', function () {
		if ( ! caught) {
			caught = true;
			throw err;
		} else {
			process.exit(1);
		}
	});
});
