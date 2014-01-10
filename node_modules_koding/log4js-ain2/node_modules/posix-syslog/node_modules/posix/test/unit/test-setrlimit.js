var assert = require('assert');
var posix = require('../../lib/posix');

var limits = [
    "core",
    "cpu",
    "data",
    "fsize",
    "nofile",
    "stack",
    "as"
];

// setrlimit: invalid input args
try {
    posix.setrlimit();
    assert.ok(false);
}
catch(e) { }

try {
    posix.setrlimit("nofile");
    assert.ok(false);
}
catch(e) { }

try {
    posix.setrlimit("foobar", {soft: 100});
    assert.ok(false);
}
catch(e) { }

// verify that RLIM_INFINITY <-> null conversion works both ways
posix.setrlimit("cpu", {soft: null, hard: null});
var now = posix.getrlimit("cpu");
assert.ok(now.soft === null);
assert.ok(now.hard === null);

// make some "nofile" adjustments
var begin = posix.getrlimit("nofile")
console.log("begin: " + JSON.stringify(begin));
posix.setrlimit("nofile", {soft: 500});
now = posix.getrlimit("nofile");
console.log("now: " + JSON.stringify(now));
assert.equal(begin.hard, now.hard);
console.log("adjusted: " + JSON.stringify(now));
assert.equal(now.soft, 500);

// setrlimit: lower each limit by one
for(var i in limits) {
    var limit = posix.getrlimit(limits[i]);
    if(limit.soft > 1) {
        console.log("setrlimit: " + limits[i] + " " + JSON.stringify(limit));
        posix.setrlimit(limits[i], {
            soft: limit.soft - 1,
            hard: limit.hard
        });
        var limit2 = posix.getrlimit(limits[i]);
        assert.equal(limit.soft - 1, limit2.soft);
        console.log(limits[i] + " was: " + JSON.stringify(limit));
        console.log(limits[i] + " now: " + JSON.stringify(limit2));
    }
}
