var assert = require('assert'),
    posix = require("../../lib/posix");

assert.throws(function () {
    posix.setregid("dummyzzz1234", -1);
}, /group id does not exist|ENOENT/);

assert.throws(function () {
    posix.setregid(-1, "dummyzzz1234");
}, /group id does not exist|ENOENT/);

function test_setregid() {
    var old_gid = posix.getegid();
    assert.equal(old_gid, 0);

    posix.setregid(-1, -1); // NOP
    assert.equal(posix.getgid(), 0);
    assert.equal(posix.getegid(), 0);

    posix.setregid(0, 0);
    assert.equal(posix.getuid(), 0);
    assert.equal(posix.getegid(), 0);

    posix.setregid(0, 2);
    assert.equal(posix.getgid(), 0);
    assert.equal(posix.getegid(), 2);

    posix.setregid("daemon", "daemon");
    assert.equal(posix.getgid(), 1);
    assert.equal(posix.getegid(), 1);

    posix.setregid(123, 456);
    assert.equal(posix.getgid(), 123);
    assert.equal(posix.getegid(), 456);
}

if(posix.getuid() == 0) {
    test_setregid()
}
else {
    console.log("warning: setregid tests skipped - not a privileged user!");
}
