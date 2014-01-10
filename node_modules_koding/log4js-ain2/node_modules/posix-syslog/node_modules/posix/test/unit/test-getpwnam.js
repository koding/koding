var assert = require('assert'),
    posix = require("../../lib/posix");

assert.throws(function() {
    posix.getpwnam();
}, /requires exactly 1 argument/);

assert.throws(function() {
    posix.getpwnam(1, 2);
}, /requires exactly 1 argument/);

assert.throws(function() {
    posix.getpwnam("doesnotexistzzz123");
}, /user id does not exist/);

assert.throws(function() {
    posix.getpwnam(65432);
}, /user id does not exist/);

var entry = posix.getpwnam("root");
console.log("getpwnam: " + JSON.stringify(entry));
assert.equal(entry.name, "root");
assert.equal(entry.uid, 0);
assert.equal(entry.gid, 0);
assert.equal(typeof(entry.gecos), "string");
assert.equal(typeof(entry.dir), "string");
assert.equal(typeof(entry.shell), "string");

assert.equal(posix.getpwnam(0).name, "root");
