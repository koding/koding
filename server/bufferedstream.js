var stream = require('stream')
  , fs = require('fs')
  , util = require('util')
  ;

var BufferedStream = function (limit) {
  if (typeof limit === 'undefined') {
    limit = Infinity;
  }
  this.limit = limit;
  this.size = 0;
  this.chunks = [];
  this.writable = true;
  this.readable = true;
}
util.inherits(BufferedStream, stream.Stream);
BufferedStream.prototype.pipe = function (dest, options) {
  var self = this
  if (self.resume) self.resume();
  stream.Stream.prototype.pipe.call(self, dest, options)
  //just incase you are piping to two streams, do not emit data twice.
  //note: you can pipe twice, but you need to pipe both streams in the same tick.
  //(this is normal for streams)
  if(this.piped)
    return dest
    
  process.nextTick(function () {
    self.chunks.forEach(function (c) {self.emit('data', c)})
    self.size = 0;
    delete self.chunks;
    if(self.ended){
      self.emit('end')
    }
  })
  this.piped = true

  return dest
}
BufferedStream.prototype.write = function (chunk) {
  if (!this.chunks) {
    this.emit('data', chunk);
    return;
  }
  this.chunks.push(chunk);
  this.size += chunk.length;
  if (this.limit < this.size) {
    this.pause();
  }
}
BufferedStream.prototype.end = function () {
  if(!this.chunks)
    this.emit('end');
  else
    this.ended = true
}

if (!stream.Stream.prototype.pause) {
  BufferedStream.prototype.pause = function() {
    this.emit('pause');
  };
}
if (!stream.Stream.prototype.resume) {
  BufferedStream.prototype.resume = function() {
    this.emit('resume');
  };
}

exports.BufferedStream = BufferedStream;