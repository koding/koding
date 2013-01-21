var falafel = require('../');
var test = require('tap').test;
var vm = require('vm');

test('array', function (t) {
    t.plan(5);
    
    var src = '(' + function () {
        var xs = [ 1, 2, [ 3, 4 ] ];
        var ys = [ 5, 6 ];
        g([ xs, ys ]);
    } + ')()';
    
    var output = falafel(src, function (node) {
        if (node.type === 'ArrayExpression') {
            node.update('fn(' + node.source() + ')');
        }
    });
    
    var arrays = [
        [ 3, 4 ],
        [ 1, 2, [ 3, 4 ] ],
        [ 5, 6 ],
        [ [ 1, 2, [ 3, 4 ] ], [ 5, 6 ] ],
    ];
    
    vm.runInNewContext(output, {
        fn : function (xs) {
            t.same(arrays.shift(), xs);
            return xs;
        },
        g : function (xs) {
            t.same(xs, [ [ 1, 2, [ 3, 4 ] ], [ 5, 6 ] ]);
        },
    });
});
