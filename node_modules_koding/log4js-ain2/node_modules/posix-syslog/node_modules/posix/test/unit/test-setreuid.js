var assert = require('assert'),
    posix = require("../../lib/posix");

assert.throws(function () {
    posix.setreuid("dummyzzz1234", -1);
}, /user id does not exist|ENOENT/);

assert.throws(function () {
    posix.setreuid(-1, "dummyzzz1234");
}, /user id does not exist|ENOENT/);

function test_setreuid() {
    var old_ruid = posix.getuid();
    assert.equal(old_ruid, 0);
    var old_euid = posix.geteuid();
    assert.equal(old_euid, 0);

    posix.setreuid(-1, -1); // NOP
    assert.equal(posix.getuid(), 0);
    assert.equal(posix.geteuid(), 0);

    posix.setreuid("root", "root");
    assert.equal(posix.getuid(), 0);
    assert.equal(posix.geteuid(), 0);

    posix.setreuid(-1, 2);
    assert.equal(process.getuid(), 0);
    assert.equal(posix.geteuid(), 2);

    posix.setreuid("root", "root");
    assert.equal(posix.getuid(), 0);
    assert.equal(posix.geteuid(), 0);

    posix.setreuid(123, 456);
    assert.equal(posix.getuid(), 123);
    assert.equal(posix.geteuid(), 456);

    posix.setreuid(123, 456); // force Saved UID to be set, too (OSX)
    assert.throws(function() {
        posix.setreuid(0, 0);
    }, /EPERM/);

    assert.equal(posix.getuid(), 123);
    assert.equal(posix.geteuid(), 456);
}

if(process.getuid() == 0) {
    test_setreuid()
}
else {
    console.log("warning: setreuid tests skipped - not a privileged user!");
}
