var assert = require('assert'),
    posix = require("../../lib/posix");

assert.throws(function() {
    posix.geteuid(123)
}, /takes no arguments/);

var uid = posix.geteuid();
console.log("geteuid: " + uid);
assert.equal(uid, process.getuid());
