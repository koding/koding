require('./harness');

var timeout = null;

connection.addListener('ready', function () {
  connection.exchange('node-publish-confirms', {type: 'fanout', confirm: true},
                      function(exchange) {
    publish = exchange.publish("", "hello", { mandatory: true });

    publish.addListener('ack', function(){clearTimeout(timeout); connection.end();});

  });
});

timeout = setTimeout(function() {
  assert.ok(1, 2);
}, 5000);


