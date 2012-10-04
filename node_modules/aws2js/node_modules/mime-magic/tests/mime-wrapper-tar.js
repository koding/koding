var mime = require('../');
var assert = require('assert');

var callback = false;

mime.fileWrapper('data/foo.txt.tar', function (err, res) {
	callback = true;
	assert.ifError(err);
	assert.deepEqual(res, 'application/x-tar');
});

process.on('exit', function () {
	assert.ok(callback);
});
