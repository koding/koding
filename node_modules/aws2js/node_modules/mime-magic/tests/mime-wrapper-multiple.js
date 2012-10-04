var mime = require('../');
var assert = require('assert');

var callback = false;

var files = [
	'data/foo.txt.bz2',
	'data/foo.txt.gz',
	'data/foo.txt.zip',
	'data/foo.txt.tar',
	'data/foo.pdf',
	'data/foo.txt'
];

var expected = [
	'application/x-bzip2',
	'application/x-gzip',
	'application/zip',
	'application/x-tar',
	'application/pdf',
	'text/plain'
];

mime.fileWrapper(files, function (err, res) {
	callback = true;
	assert.ifError(err);
	console.log(res);
	for (var i in res) {
		assert.deepEqual(res[i], expected[i]);
	}
});

process.on('exit', function () {
	assert.ok(callback);
});
