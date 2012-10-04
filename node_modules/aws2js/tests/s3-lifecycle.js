'use strict';

var assert = require('assert');
var s3 = require('../').load('s3');

var callbacks = {
	putLifeCycleRule1: false,
	putLifeCycleRule2: false,
	delLifeCycleRule1: false,
	delLifeCycleRule2: false
};

var timestamp = new Date().getTime();

var showError = function (err) {
	if (err) {
		console.error(err);
	}
};

s3.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
s3.setBucket(process.env.AWS2JS_S3_BUCKET);

s3.delLifeCycle(function (error, response) {
	console.log('s3.delLifeCycle');
	showError(error);
	assert.ifError(error);
	
	s3.putLifeCycleRule('id', 'prefix-' + timestamp, 5, function (error, response) {
		callbacks.putLifeCycleRule1 = true;
		
		console.log('s3.putLifeCycleRule: id, prefix-' + timestamp);
		showError(error);
		assert.ifError(error);
		
		s3.putLifeCycleRule('id2', 'otherprefix-' + timestamp, 5, function (error, response) {
			callbacks.putLifeCycleRule2 = true;
			
			console.log('s3.putLifeCycleRule: id2, otherprefix-' + timestamp);
			showError(error);
			assert.ifError(error);
			
			setTimeout(function () {
				s3.delLifeCycleRule('id', function(error, response) {
					callbacks.delLifeCycleRule1 = true;
					
					console.log('s3.delLifeCycleRule: id');
					showError(error);
					assert.ifError(error);
					
					s3.delLifeCycleRule('id2', function(error, response) {
						callbacks.delLifeCycleRule2 = true;
						
						console.log('s3.delLifeCycleRule: id2');
						showError(error);
						assert.ifError(error);
					});
				});
			}, 10000);
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
