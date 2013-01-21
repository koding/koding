var esprima = require('esprima');

var traverse = function (node, cb) {
    if (Array.isArray(node)) {
        node.forEach(function (x) {
            traverse(x, cb);
        });
    }
    else if (node && typeof node === 'object') {
        cb(node);
        
        Object.keys(node).forEach(function (key) {
            traverse(node[key], cb);
        });
    }
};

var walk = function (src, cb) {
    var ast = esprima.parse(src);
    traverse(ast, cb);
};

var walkSlow = function (src, cb) {
    var ast = esprima.parse(src, { range : true });
    traverse(ast, cb);
};

var exports = module.exports = function (src, opts) {
    return exports.find(src, opts).strings;
};

exports.find = function (src, opts) {
    if (!opts) opts = {};
    var word = opts.word === undefined ? 'require' : opts.word;
    if (typeof src !== 'string') src = String(src);
    
    function isRequire (node) {
        return node.type === 'CallExpression'
            && node.callee.type === 'Identifier'
            && node.callee.name === word
        ;
    }
    
    var modules = { strings : [], expressions : [] };
    
    if (src.indexOf(word) == -1) return modules;
    
    var slowPass = false;
    
    walk(src, function (node) {
        if (!isRequire(node)) return;
        if (node.arguments.length
        && node.arguments[0].type === 'Literal') {
            modules.strings.push(node.arguments[0].value);
        }
        else {
            slowPass = true;
        }
    });
    
    if (slowPass) {
        walkSlow(src, function (node) {
            if (!isRequire(node)) return;
            if (!node.arguments.length
            || node.arguments[0].type !== 'Literal') {
                var r = node.arguments[0].range;
                var s = src.slice(r[0], r[1] + 1);
                modules.expressions.push(s);
            }
        });
    }
    
    return modules;
};
