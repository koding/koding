var assert = require('assert');
var posix = require("../../lib/posix");

assert.throws(function () {
    posix.openlog("foobar", 1);
}, /invalid syslog constant value/);

assert.throws(function () {
    posix.closelog("foobar");
}, /does not take any arg/);

assert.throws(function () {
    posix.openlog("foobar", {"xxx": 1}, "local0");
}, /invalid syslog constant value/);

assert.throws(function () {
    posix.openlog("foobar", {}, "xxx");
}, /invalid syslog constant value/);

posix.openlog("test-node-syslog", {cons: true, ndelay: true, pid: true}, "local0");
posix.setlogmask({info:1, debug:1});
var old = posix.setlogmask({emerg:1, alert:1, crit:1, err:1, warning:1,
                            notice:1, info:1, debug:1});
posix.syslog("info", "hello from node-posix (info)");
posix.closelog();
