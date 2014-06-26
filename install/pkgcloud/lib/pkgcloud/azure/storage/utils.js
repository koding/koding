var util = require('util'),
    Stream = require('stream').Stream;

var ChunkedStream = exports.ChunkedStream = function ChunkedStream(chunk) {
  Stream.call(this);

  this.writable = true;
  this.readable = true;

  this.ended = false;
  this.paused = false;
  this.size = 0;
  this.chunk = chunk;
  this.buffer = [];
  this.chunkBuffer = [];
};

util.inherits(ChunkedStream, Stream);

ChunkedStream.prototype.write = function write(data, encoding) {
  if (!Buffer.isBuffer(data)) {
    data = new Buffer(data, encoding);
  }
  this.buffer.push(data);
  this.size += data.length;

  // Split data in chunks
  while (this.size >= this.chunk) {
    var total = 0,
        parts = [];

    this.buffer = this.buffer.filter(function (part) {
      if (total >= this.chunk) return true;

      parts.push(part);
      total += part.length;
      return false;
    }, this);

    // Last chunk is bigger than we need
    if (total > this.chunk) {
      var last = parts[parts.length - 1],
          splitPos = last.length - total + this.chunk,
          head = last.slice(0, splitPos),
          tail = last.slice(splitPos);

      parts[parts.length - 1] = head;

      // Return tail back to main buffer
      this.buffer.unshift(tail);
    }

    this.emitChunk(Buffer.concat(parts, this.chunk));
    this.size -= this.chunk;
  }

  if (this.paused) return false;
};

ChunkedStream.prototype.end = function end() {
  if (this.ended) return;

  // Emit all left data
  var self = this;
  this.ended = true;
  this.emitChunk(Buffer.concat(this.buffer, this.size));
  this.buffer = [];
  this.size = 0;

  this.emit('end');
};
ChunkedStream.prototype.close = ChunkedStream.prototype.end;

ChunkedStream.prototype.emitChunk = function emitChunk(chunk) {
  if (this.paused) {
    this.chunkBuffer.push(chunk);
    return;
  }
  this.emit('data', chunk);
};

ChunkedStream.prototype.pause = function pause() {
  if (this.paused) return;
  this.paused = true;
};

ChunkedStream.prototype.resume = function resume() {
  if (!this.paused) return;
  this.paused = false;

  // Emit all accumulated data
  this.chunkBuffer.forEach(function (chunk) {
    this.emit('data', chunk);
  }, this);
  this.chunkBuffer = [];

  this.emit('drain');
};
