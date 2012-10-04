var mime = require('../');
var assert = require('assert');

var callback = false;

mime.fileWrapper('data/foo.txt.gz', function (err, res) {
	callback = true;
	assert.ifError(err);
	assert.deepEqual(res, 'application/x-gzip');
});

process.on('exit', function () {
	assert.ok(callback);
});
