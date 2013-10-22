global.options = { heartbeat: 1 };

require('./harness').run();

var isClosed = false, q;

setTimeout(function() {
  assert.ok(!isClosed);
  // Change the local heartbeat interval (without changing the negotiated
  // interval).  This will cause the server to notice we've dropped off,
  // and close the connection.
  connection.options['heartbeat'] = 0;
  setTimeout(function() { 
    assert.ok(isClosed); 
  }, 3500);
}, 1000);

connection.on('heartbeat', function() {
  puts(" <- heartbeat");
});
connection.on('close', function() {
  puts("closed");
  isClosed = true;
});
connection.addListener('ready', function () {
  puts("connected to " + connection.serverProperties.product);

  q = connection.queue('node-test-heartbeat', {autoDelete: true});
  q.on('queueDeclareOk', function (args) {
    puts('queue opened.');
    assert.equal(0, args.messageCount);
    assert.equal(0, args.consumerCount);

    q.bind("#");
    q.subscribe(function(json) {
      // We should not be subscribed to the queue, the heartbeat will peter out before.
      assert.ok(false);
    });
  });
});