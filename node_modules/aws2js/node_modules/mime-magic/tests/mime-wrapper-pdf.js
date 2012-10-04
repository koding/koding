var mime = require('../');
var assert = require('assert');

var callback = false;

mime.fileWrapper('data/foo.pdf', function (err, res) {
	callback = true;
	assert.ifError(err);
	assert.deepEqual(res, 'application/pdf');
});

process.on('exit', function () {
	assert.ok(callback);
});
