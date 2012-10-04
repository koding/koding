var p = require('path');
var cp = require('child_process');

var fileExec = p.resolve(__dirname + '/../bin/file');
var fileFlags = ['--magic-file', p.resolve(__dirname + '/../share/magic.mgc'), '--brief', '--mime-type'];

/**
 * Sets the environment for the library loader
 * 
 * @param {String} ld
 */
var setEnv = function (ld) {
	if (process.env[ld] === undefined) {
		process.env[ld] = p.resolve(__dirname + '/../lib');
	} else {
		process.env[ld] = process.env[ld] + ':' + p.resolve(__dirname + '/../lib');
	}
};

/**
 * Wrapper for the file(1) utility
 * 
 * @param path
 * @param {Function} cb
 */
var fileWrapper = function (path, cb) {
	cp.execFile(fileExec, fileFlags.concat(Array.isArray(path) ? path : [path]), function (err, stdout) {
		stdout = stdout.trim();
		if (err) {
			if (stdout) {
				err.message = stdout;
			}
			cb(err);
		} else {
			cb(null, Array.isArray(path) ? stdout.split(/\r\n|\n|\r/) : stdout);
		}
	});
};
exports.fileWrapper = fileWrapper;

setEnv('LD_LIBRARY_PATH');
setEnv('DYLD_LIBRARY_PATH');
