var conn = require('./harness').createConnection();

var recvCount = 0;
var body = "Some say the devil is dead";

var later = function(fun) {
    setTimeout(fun, 500);
};
conn.once('ready', function () {
  puts("connected to " + conn.serverProperties.product);

  var q = conn.queue('node-simple-queue');
  var exchange = conn.exchange('node-simple-fanout', {type: 'fanout'});

  exchange.once('open', function(){
    q.bind(exchange, "");

    q.subscribe(function(message){
      recvCount+=1;
    });

    exchange.publish('', body);

    q.unbind(exchange, "");
    later(function(){
      // This will emit a NOT_FOUND error b/c we're no longer bound to the exchange
      var thrown = false;
      conn.addListener('error', function(e){
        thrown = true;
        assert.equal(e.code, 404);
      });
      exchange.publish('', body);
      // Wait a bit before ending so we can receive the message if it does come (it shouldn't).
      later(function() {
        assert.ok(thrown);
        conn.end();
        process.exit();
      });
    });
  });
});

process.addListener('exit', function () {
    assert.equal(1, recvCount);
});
