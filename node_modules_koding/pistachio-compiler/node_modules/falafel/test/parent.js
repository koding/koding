var falafel = require('../');
var test = require('tap').test;
var vm = require('vm');

test('parent', function (t) {
    t.plan(5);
    
    var src = '(' + function () {
        var xs = [ 1, 2, 3 ];
        fn(ys);
    } + ')()';
    
    var output = falafel(src, function (node) {
        if (node.type === 'ArrayExpression') {
            t.equal(node.parent.type, 'VariableDeclarator');
            t.equal(node.parent.source(), 'xs = [ 1, 2, 3 ]');
            t.equal(node.parent.parent.type, 'VariableDeclaration');
            t.equal(node.parent.parent.source(), 'var xs = [ 1, 2, 3 ];');
            node.parent.update('ys = 4;');
        }
    });
    
    vm.runInNewContext(output, {
        fn : function (x) {
            t.equal(x, 4);
        },
    });
});
