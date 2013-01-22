var EventEmitter = require('events').EventEmitter;
var util = require('util');
try {
	var expat = require('../build/Release/node-expat');
} catch(e) {
	var expat = require('../build/default/node-expat');
}

/**
 * Simple wrapper because EventEmitter has turned pure-JS as of node
 * 0.5.x.
 */
exports.Parser = function(encoding) {
    this.parser = new expat.Parser(encoding);

    var that = this;
    this.parser.emit = function() {
	that.emit.apply(that, arguments);
    };
};
util.inherits(exports.Parser, EventEmitter);

exports.Parser.prototype.parse = function(buf, isFinal) {
    return this.parser.parse(buf, isFinal);
};

exports.Parser.prototype.setEncoding = function(encoding) {
    return this.parser.setEncoding(encoding);
};

exports.Parser.prototype.getError = function() {
    return this.parser.getError();
};
exports.Parser.prototype.stop = function() {
    return this.parser.stop();
};
exports.Parser.prototype.pause = function() {
    return this.stop();
};
exports.Parser.prototype.resume = function() {
    return this.parser.resume();
};
