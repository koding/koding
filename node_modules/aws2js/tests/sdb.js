'use strict';

var assert = require('assert');

var sdbEast = require('../').load('sdb');
var sdbWest = require('../').load('sdb');

sdbEast.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
sdbEast.setRegion('us-east-1');

sdbWest.setCredentials(process.env.AWS_ACCEESS_KEY_ID, process.env.AWS_SECRET_ACCESS_KEY);
sdbWest.setRegion('us-west-1');

var callbacks = {
	requestEast: false,
	requestEastWithoutQuery: false,
	requestEastWithQuery: false,
	requestWest: false,
	requestWestWithoutQuery: false,
	requestWestWithQuery: false
};

var sdbProcessResponse = function (err, res) {
	assert.ifError(err);
	assert.ok(res.ListDomainsResult);
};

sdbEast.request('ListDomains', {}, function (err, res) {
	callbacks.requestEast = true;
	sdbProcessResponse(err, res);
});

sdbEast.request('ListDomains', function (err, res) {
	callbacks.requestEastWithoutQuery = true;
	sdbProcessResponse(err, res);
});

sdbEast.request('ListDomains', {MaxNumberOfDomains: 10}, function (err, res) {
	callbacks.requestEastWithQuery = true;
	sdbProcessResponse(err, res);
});

sdbWest.request('ListDomains', {}, function (err, res) {
	callbacks.requestWest = true;
	sdbProcessResponse(err, res);
});

sdbWest.request('ListDomains', function (err, res) {
	callbacks.requestWestWithoutQuery = true;
	sdbProcessResponse(err, res);
});

sdbWest.request('ListDomains', {MaxNumberOfDomains: 10}, function (err, res) {
	callbacks.requestWestWithQuery = true;
	sdbProcessResponse(err, res);
});

process.on('exit', function () {
	var i;
	for (i in callbacks) {
		if (callbacks.hasOwnProperty(i)) {
			assert.ok(callbacks[i]);
		}
	}
});
