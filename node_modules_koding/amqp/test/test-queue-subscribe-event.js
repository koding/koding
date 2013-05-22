require('./harness');

var basic_qos_emitted = false;

// make sure the 'basicQosOk' event is emitted properly with prefetchCount: 0
connection.on('ready', function() {
  var e = connection.exchange('node-subscribe-event', {type: 'fanout'});
  connection.queue('node-subscribe-event-queue', function(q) {
    q.bind(e, '');
    q.subscribe({ ack: true, prefetchCount: 0 }, function() {
      connection.end();
    });

    q.on('basicQosOk', function() {
      basic_qos_emitted = true;
    });

    e.publish('node-subscribe-event-queue', { foo: 'bar' });
  });
});


process.on('exit', function() {
  assert( basic_qos_emitted );
});
