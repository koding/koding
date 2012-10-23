var buffer = require('../index.js');
var test = require('tap').test;

test('utf8 buffer to base64', function (t) {
    t.plan(1);
    t.equal(
        new buffer.Buffer("Ձאab", "utf8").toString("base64"),
        new Buffer("Ձאab", "utf8").toString("base64")
    );
    t.end();
});

test('utf8 buffer to hex', function (t) {
    t.plan(1);
    t.equal(
        new buffer.Buffer("Ձאab", "utf8").toString("hex"),
        new Buffer("Ձאab", "utf8").toString("hex")
    );
    t.end();
});

test('ascii buffer to base64', function (t) {
    t.plan(1);
    t.equal(
        new buffer.Buffer("123456!@#$%^", "ascii").toString("base64"),
        new Buffer("123456!@#$%^", "ascii").toString("base64")
    );
    t.end();
});

test('ascii buffer to hex', function (t) {
    t.plan(1);
    t.equal(
        new buffer.Buffer("123456!@#$%^", "ascii").toString("hex"),
        new Buffer("123456!@#$%^", "ascii").toString("hex")
    );
    t.end();
});

test('base64 buffer to utf8', function (t) {
    t.plan(1);
    t.equal(
        new buffer.Buffer("1YHXkGFi", "base64").toString("utf8"),
        new Buffer("1YHXkGFi", "base64").toString("utf8")
    );
    t.end();
});

test('hex buffer to utf8', function (t) {
    t.plan(1);
    t.equal(
        new buffer.Buffer("d581d7906162", "hex").toString("utf8"),
        new Buffer("d581d7906162", "hex").toString("utf8")
    );
    t.end();
});

test('base64 buffer to ascii', function (t) {
    t.plan(1);
    t.equal(
        new buffer.Buffer("MTIzNDU2IUAjJCVe", "base64").toString("ascii"),
        new Buffer("MTIzNDU2IUAjJCVe", "base64").toString("ascii")
    );
    t.end();
});

test('hex buffer to ascii', function (t) {
    t.plan(1);
    t.equal(
        new buffer.Buffer("31323334353621402324255e", "hex").toString("ascii"),
        new Buffer("31323334353621402324255e", "hex").toString("ascii")
    );
    t.end();
});

test("hex of write{Uint,Int}{8,16,32}{LE,BE}", function(t) {
    t.plan(2*2*2+2);
    ["UInt","Int"].forEach(function(x){
        [8,16,32].forEach(function(y){
            var endianesses = (y === 8) ? [""] : ["LE","BE"];
            endianesses.forEach(function(z){
                var v1  = new buffer.Buffer(y / 8);
                var v2  = new Buffer(y / 8);
                var fn  = "write" + x + y + z;
                var val = (x === "Int") ? -3 : 3;
                v1[fn](val, 0);
                v2[fn](val, 0);
                t.equal(
                    v1.toString("hex"),
                    v2.toString("hex")
                );
            });
        });
    });
    t.end();
});
