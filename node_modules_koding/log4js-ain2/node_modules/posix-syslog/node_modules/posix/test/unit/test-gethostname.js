var assert = require('assert');
var posix = require('../../lib/posix');
var os = require('os');

var hostname = posix.gethostname();
console.log('hostname: ' + hostname);
assert.ok(hostname === os.hostname());
