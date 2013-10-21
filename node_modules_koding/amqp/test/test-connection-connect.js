var harness = require('./harness');

// 50% of the time, this will throw as it attempts to connect to 'nohost'. We want that, it should reconnect
// to options.host the next time.
var conn = new amqp.Connection();

conn.on('ready', function() {
  conn.destroy();
});

conn._createSocket();
conn._startHandshake();
