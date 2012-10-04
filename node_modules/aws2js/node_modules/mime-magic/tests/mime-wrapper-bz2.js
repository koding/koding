var mime = require('../');
var assert = require('assert');

var callback = false;

mime.fileWrapper('data/foo.txt.bz2', function (err, res) {
	callback = true;
	assert.ifError(err);
	assert.deepEqual(res, 'application/x-bzip2');
});

process.on('exit', function () {
	assert.ok(callback);
});
