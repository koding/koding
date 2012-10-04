var tap = require("tap"),
    test = tap.test,
    plan = tap.plan;
var esc = require('../lib/esc.js');

test("test our own esc(...)", function (t) {
    var query1 = 'DomainName';
    var escQuery1 = esc(query1);
    t.equal(escQuery1, 'DomainName', 'Simple String (idempotent)');

    var query2 = 2;
    var escQuery2 = esc(query2);
    t.equal(escQuery2, '2', 'Simple Number Escape (idempotent)');

    var query3 = 'String Value';
    var escQuery3 = esc(query3);
    t.equal(escQuery3, 'String%20Value', 'Simple With a Space');

    var query4 = 'Hey @andychilton, read this! #liverpool';
    var escQuery4 = esc(query4);
    t.equal(escQuery4, 'Hey%20%40andychilton%2C%20read%20this%21%20%23liverpool', 'Something akin to a Tweet');

    var query5 = 'SELECT * FROM my_table';
    var escQuery5 = esc(query5);
    t.equal(escQuery5, 'SELECT%20%2A%20FROM%20my_table', 'Escaping of a select');

    var signature = 'wOJIO9A2W5mFwDgiDvZbTSMK%2FPY%3D';

    var url = 'http://example.com/request';
    var escUrl = esc(url);
    console.log(url, escUrl);
    t.equal(escUrl, 'http%3A%2F%2Fexample.com%2Frequest', 'Escaping of a URL');

    t.end();
});
