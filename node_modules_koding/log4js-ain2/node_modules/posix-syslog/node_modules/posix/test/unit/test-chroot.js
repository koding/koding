var assert = require('assert'),
    fs = require('fs'),
    posix = require("../../lib/posix");

function test_chroot() {
    assert.throws(function () {
        posix.chroot('/path/does/not/exist');
    }, /ENOENT/);

    console.log("chroot to: " + __dirname);
    posix.chroot(__dirname);
    console.log("contents of root dir after chroot: " + fs.readdirSync("/"));
    var this_file_in_chroot = fs.statSync("/test-chroot.js");
    assert.ok(this_file_in_chroot);
    assert.ok(this_file_in_chroot.isFile());
}

if(process.getuid() == 0) {
    test_chroot()
}
else {
    console.log("warning: chroot tests skipped - not a privileged user!");
}
