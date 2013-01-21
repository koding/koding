buffertools = require('./buffertools.node');
SlowBuffer = require('buffer').SlowBuffer;
Buffer = require('buffer').Buffer;

// requires node 3.1
events = require('events');
util = require('util');

// extend object prototypes
for (var property in buffertools) {
	exports[property] = Buffer.prototype[property] = SlowBuffer.prototype[property] = buffertools[property];
}

// bug fix, see https://github.com/bnoordhuis/node-buffertools/issues/#issue/6
Buffer.prototype.concat = SlowBuffer.prototype.concat = function() {
	var args = [this].concat(Array.prototype.slice.call(arguments));
	return buffertools.concat.apply(buffertools, args);
};

//
// WritableBufferStream
//
// - never emits 'error'
// - never emits 'drain'
//
function WritableBufferStream() {
	this.writable = true;
	this.buffer = null;
}

util.inherits(WritableBufferStream, events.EventEmitter);

WritableBufferStream.prototype._append = function(buffer, encoding) {
	if (!this.writable) {
		throw new Error('Stream is not writable.');
	}

	if (Buffer.isBuffer(buffer)) {
		// no action required
	}
	else if (typeof buffer == 'string') {
		// TODO optimize
		buffer = new Buffer(buffer, encoding || 'utf8');
	}
	else {
		throw new Error('Argument should be either a buffer or a string.');
	}

	// FIXME optimize!
	if (this.buffer) {
		this.buffer = buffertools.concat(this.buffer, buffer);
	}
	else {
		this.buffer = new Buffer(buffer.length);
		buffer.copy(this.buffer);
	}
};

WritableBufferStream.prototype.write = function(buffer, encoding) {
	this._append(buffer, encoding);

	// signal that it's safe to immediately write again
	return true;
};

WritableBufferStream.prototype.end = function(buffer, encoding) {
	if (buffer) {
		this._append(buffer, encoding);
	}

	this.emit('close');

	this.writable = false;
};

WritableBufferStream.prototype.getBuffer = function() {
	if (this.buffer) {
		return this.buffer;
	}
	return new Buffer(0);
};

WritableBufferStream.prototype.toString = function() {
	return this.getBuffer().toString();
};

exports.WritableBufferStream = WritableBufferStream;
