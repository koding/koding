var assert = require('assert'),
    posix = require("../../lib/posix");

assert.throws(function() {
    posix.getgrnam();
}, /requires exactly 1 argument/);

assert.throws(function() {
    posix.getgrnam(1, 2);
}, /requires exactly 1 argument/);

assert.throws(function() {
    posix.getgrnam("doesnotexistzzz123");
}, /group id does not exist/);

assert.throws(function() {
    posix.getgrnam(65432);
}, /group id does not exist/);

var entry = posix.getgrnam("daemon");
console.log("getgrnam: " + JSON.stringify(entry));
assert.equal(entry.name, "daemon");
assert.equal(typeof(entry.gid), "number");
assert.equal(typeof(entry.passwd), "string");


assert.equal(posix.getgrnam(entry.gid).name, "daemon");
