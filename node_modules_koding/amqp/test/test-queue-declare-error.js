helper = require('./harness').run();

connection.removeListener('error', errorCallback);

assert = require('assert');

connection.on('ready', function() {
  puts("connected to " + connection.serverProperties.product);

  connection.queue('node-will-not-see-this', { passive: true }, function(q) {
    assert.ok(false, 'Not supposed to see this message.');
    process.exit(1);
  });
  
  connection.on('error', function (exception) {
    message = String(exception.message);
    assert.equal(true, message.indexOf('NOT_FOUND') === 0, 'This supposed to be a "NOT_FOUND" error.');
    process.exit(0);
  });
});
