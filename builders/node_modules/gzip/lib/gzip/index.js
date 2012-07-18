var spawn = require('child_process').spawn,
    Buffer = require('buffer').Buffer;

module.exports = function(data) {
  var rate = 8,
      enc = 'utf8',
      isBuffer = Buffer.isBuffer(data),
      args = Array.prototype.slice.call(arguments, 1),
      callback;
  
  if (!isBuffer && typeof args[0] === 'string') {
    enc = args.shift();
  }
  
  if (typeof args[0] === 'number') {
    rate = args.shift() - 0;
  }
  callback = args[0];
  
  var gzip = spawn('gzip', ['-' + (rate-0),'-c', '-']);
  
  var promise = new process.EventEmitter,
      output = [],
      output_len = 0;
  
  // No need to use buffer if no callback was provided
  if (callback) {
    gzip.stdout.on('data', function(data) {  
      output.push(data);
      output_len += data.length;
    });
    
    gzip.on('exit', function(code) {
      var buf = new Buffer(output_len);
    
      for (var a = 0, p = 0; p < output_len; p += output[a++].length) {      
        output[a].copy(buf, p, 0);

      }
      
      callback(code, buf);
    });
  }
  
  // Promise events
  gzip.stdout.on('data', function(data) {
    promise.emit('data', data);
  });
  gzip.on('exit', function(code) {
    promise.emit('end');    
  });
  
  if (isBuffer) {    
    gzip.stdin.encoding = 'binary';    
    gzip.stdin.end(data.length ? data: '');
  } else {  
    gzip.stdin.end(data ? data.toString() : '', enc);
  }
  
  // Return EventEmitter, so node.gzip can be used for streaming
  // (thx @indexzero for that tip)
  return promise;
};
