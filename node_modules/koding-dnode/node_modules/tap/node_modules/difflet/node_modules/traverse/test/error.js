var assert = require('assert');
var Traverse = require('../');

exports['traverse an Error'] = function () {
    var obj = new Error("test");

    var results = Traverse(obj).map(function (node) { });

    assert.deepEqual(results, {
        message: 'test'
    });
};

