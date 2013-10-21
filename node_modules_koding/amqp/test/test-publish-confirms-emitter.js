require('./harness').run();

var timeout = null;
var confirmed = 0;

connection.addListener('ready', function () {
  connection.exchange('node-publish-confirms', {type: 'fanout', confirm: true}, function(exchange) {
    var publish = exchange.publish("", "hello", { mandatory: true });

    publish.addListener('ack', function(){
      confirmed++;
      clearTimeout(timeout); 
      connection.end();
    });

  });
});

timeout = setTimeout(function() {
  process.exit();
}, 1000);

process.on('exit', function(){
  assert.equal(confirmed, 1);
});


