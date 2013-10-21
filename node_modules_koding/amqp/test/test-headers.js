require('./harness').run();

var recvCount = 0;
var body = "the devil is in the headers";

connection.on('ready', function () {
  puts("connected to " + connection.serverProperties.product);

  var exchange = connection.exchange('node-h-fanout', {type: 'fanout'});

  connection.queue('node-h-queue', function(q) {
    q.bind(exchange, "*")
    q.on('queueBindOk', function() {
      q.on('basicConsumeOk', function () {
        puts("publishing message");
        exchange.publish("to.me", body, { headers: { 
            foo: 'bar', 
            bar: 'foo',
            number: '123',
            stuff: [{x:1}, {x:2}]
        } });

        setTimeout(function () {
          // wait one second to receive the message, then quit
          connection.end();
        }, 1000);
      });
      q.subscribeRaw(function (m) {
        puts("--- Message (" + m.deliveryTag + ", '" + m.routingKey + "') ---");
        //puts("--- headers: " + JSON.stringify(m.headers));
        
        recvCount++;
        assert.equal('bar', m.headers['foo']);
        assert.equal('foo', m.headers['bar']);
        assert.equal('123', m.headers['number'].toString());
        assert.equal(1, m.headers['stuff'][0].x);
        assert.equal(2, m.headers['stuff'][1].x);
      })
    })
  });
});

process.addListener('exit', function () {
  assert.equal(1, recvCount);
});
