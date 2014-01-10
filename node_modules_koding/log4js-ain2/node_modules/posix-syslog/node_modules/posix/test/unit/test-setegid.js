var assert = require('assert'),
    posix = require("../../lib/posix");

assert.throws(function () {
    posix.setegid("dummyzzz1234");
}, /group id does not exist|ENOENT/);

function test_setegid() {
    var old = posix.getegid();
    assert.equal(old, 0);

    posix.setegid("daemon");
    assert.equal(posix.getegid(), 1);

    posix.setegid(0);
    assert.equal(posix.getegid(), 0);

    posix.setegid(123);
    assert.equal(posix.getegid(), 123);

    posix.setegid(0);
    assert.equal(posix.getegid(), 0);
}

if(process.getuid() == 0) {
    test_setegid()
}
else {
    console.log("warning: setegid tests skipped - not a privileged user!");
}
