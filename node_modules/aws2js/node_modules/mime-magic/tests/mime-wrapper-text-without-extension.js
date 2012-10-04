var mime = require('../');
var assert = require('assert');

var callback = false;

mime.fileWrapper('data/foo', function (err, res) {
	callback = true;
	assert.ifError(err);
	assert.deepEqual(res, 'text/plain');
});

process.on('exit', function () {
	assert.ok(callback);
});
