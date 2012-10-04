'use strict';

var http = require('http-get');
var assert = require('assert');
var s3 = require('../').load('s3');

var path = 'foo.png';

var callbacks = {
	put: false,
	del: false
};

s3.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
s3.setBucket(process.env.AWS2JS_S3_BUCKET);

s3.putFile(path, './data/foo.png', false, {}, function (err, res) {
	callbacks.put = true;
	assert.ifError(err);
	
	var time = new Date();
	time.setMinutes(time.getMinutes() + 60);
	
	http.head({url: s3.signUrl('https', 'HEAD', path, time)}, function (err, res) {
		assert.ifError(err);
		assert.deepEqual(res.headers['content-type'], 'image/png');
		
		http.head({url: 'https://' + s3.getEndPoint() + '/' + path}, function (err, res) {
			assert.ok(err instanceof Error);
			assert.deepEqual(err.code, 403);
			
			s3.del(path, function (err) {
				callbacks.del = true;
				assert.ifError(err);
			});
		});
	});
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
