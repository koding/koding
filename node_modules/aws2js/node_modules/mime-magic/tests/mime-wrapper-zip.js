var mime = require('../');
var assert = require('assert');

var callback = false;

mime.fileWrapper('data/foo.txt.zip', function (err, res) {
	callback = true;
	assert.ifError(err);
	assert.deepEqual(res, 'application/zip');
});

process.on('exit', function () {
	assert.ok(callback);
});
