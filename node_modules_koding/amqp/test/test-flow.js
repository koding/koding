require('./harness').run();

var recvCount = 0;
var pubCount = 0;
var timeOutFired = false

connection.addListener('ready', function () {
  puts("connected to " + connection.serverProperties.product);

  var e = connection.exchange('node-flow-fanout', {type: 'fanout'});
  var q = connection.queue('node-flow-queue', function() {
    q.bind(e, "*")
    q.on('queueBindOk', function() {
      q.on('basicConsumeOk', function () {
        puts("publishing 1 json message");
        e.publish('ackmessage.json1', { name: 'A' });
        pubCount++
      });
      
      q.subscribe({ ack: true, prefetchCount: 5 }, function (json) {
        recvCount++;
        puts('Got message ' + JSON.stringify(json));
        if (recvCount == 1) {
          puts('Got message 1.. stop flow');
          var f = q.flow(false).addCallback(function(ok){
            puts("puts flow turned to passive");
            puts("publishing another json message");
            e.publish('ackmessage.json2', { name: 'B' });
            pubCount++
          });

          assert.equal('A', json.name);
          setTimeout(function () {
            timeOutFired = true
            q.flow(true).addCallback(function(ok){
              puts("flow turned back to active")
            });
          }, 1000);

        } else if (recvCount == 2) {
          puts('got message 2');
          assert.equal('B', json.name);
          assert(timeOutFired);

          puts('closing connection');
          connection.end();

        } else {
          throw new Error('Too many message!');
        }
      })
    })
  });
});


process.addListener('exit', function () {
  assert.equal(2, recvCount);
  assert.equal(2, pubCount);
});
