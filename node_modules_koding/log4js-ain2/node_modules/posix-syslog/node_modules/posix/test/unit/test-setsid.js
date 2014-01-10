var assert = require('assert');
var posix = require("../../lib/posix");

////////////////////////////////////////
// getpgid()
assert.throws(function () {
    posix.getpgid();
}, /exactly one argument/);

var my_pgid = posix.getpgid(0);
assert.ok(my_pgid > 0);
assert.notEqual(my_pgid, process.pid);

var parent_pgid = posix.getpgid(posix.getppid());
assert.equal(my_pgid, parent_pgid);

assert.equal(posix.getpgid(1), 1); // init always has pgid==1

////////////////////////////////////////
// setsid()
assert.throws(function () {
    posix.setsid(123);
}, /takes no arguments/);

var sid = posix.setsid();
console.log("setsid: " + sid);
assert.equal(sid, process.pid);
assert.equal(sid, posix.getpgid(0));

assert.throws(function () {
    posix.setsid();
}, /EPERM/);

////////////////////////////////////////
// wrappers
assert.equal(posix.getpgid(0), posix.getpgrp());
