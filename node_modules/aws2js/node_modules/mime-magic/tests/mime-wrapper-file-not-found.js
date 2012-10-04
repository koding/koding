var mime = require('../');
var assert = require('assert');

var callback = false;

mime.fileWrapper('data/foobar', function (err, res) {
	callback = true;
	assert.ok(err instanceof Error);
	assert.equal(err.code, 1);
});

process.on('exit', function () {
	assert.ok(callback);
});
