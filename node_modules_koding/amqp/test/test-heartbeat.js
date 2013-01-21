global.options = { heartbeat: 1 };

require('./harness');

var closed = false;

setTimeout(function() {
  assert.ok(!closed);
  // Change the local heartbeat interval (without changing the negotiated
  // interval).  This will cause the server to notice we've dropped off,
  // and close the connection.
  connection.options['heartbeat'] = 0;
  setTimeout(function() { assert.ok(closed); }, 3500);
}, 5000);

connection.on('heartbeat', function() {
  puts(" <- heartbeat");
});
connection.on('close', function() {
  puts("closed");
  closed = true;
});
connection.addListener('ready', function () {
  puts("connected to " + connection.serverProperties.product);

  var e = connection.exchange();

  var q = connection.queue('node-test-hearbeat', {autoDelete: true});
  q.on('queueDeclareOk', function (args) {
    puts('queue opened.');
    assert.equal(0, args.messageCount);
    assert.equal(0, args.consumerCount);

    q.bind(e, "#");
    q.subscribe(function(json) {
      assert.ok(false);
    });
  });
});
