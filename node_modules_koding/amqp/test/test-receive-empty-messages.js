require('./harness').run();

var timeout = null;
connection.addListener('ready', function () {
  var exc = connection.exchange('node-json-exchange');
  
  connection.queue('node-json-queue', function(q) {
    q.bind('node-json-exchange', '*');

    q.subscribe(function (json, headers, deliveryInfo) {
      clearTimeout(timeout);
      connection.end();
    }).addCallback(function () {
      puts("Publishing one empty message.");
      exc.publish('node-json-queue', '');
    });
  });
});

timeout = setTimeout(function() {
  puts("ERROR: Timeout occurred!!!!!!!");
  connection.end();
  assert.ok(1, 2);
}, 5000);


