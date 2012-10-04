'use strict';

var assert = require('assert');
var elasticache = require('../').load('elasticache');

elasticache.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);

try {
	elasticache.setRegion('us-east-1');
} catch (e) {
	assert.ok(e instanceof Error);
}

var callbacks = {
	request: false,
	requestWithoutQuery: false
};

var elasticacheProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.DescribeCacheClustersResult.CacheClusters);
};

elasticache.request('DescribeCacheClusters', {}, function (err, res) {
	callbacks.request = true;
	elasticacheProcessResponse(err, res);
});

elasticache.request('DescribeCacheClusters', function (err, res) {
	callbacks.requestWithoutQuery = true;
	elasticacheProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
