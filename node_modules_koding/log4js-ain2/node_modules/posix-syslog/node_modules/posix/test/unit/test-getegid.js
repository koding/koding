var assert = require('assert'),
    posix = require("../../lib/posix");

assert.throws(function() {
    posix.getegid(123)
}, /takes no arguments/);

var gid = posix.getegid();
console.log("getegid: " + gid);
assert.equal(gid, process.getgid());
