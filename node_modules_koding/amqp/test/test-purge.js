require('./harness').run();

var recvCount = 0;
var body = "hello world";

connection.addListener('ready', function () {
  puts("connected to " + connection.serverProperties.product);

  var e = connection.exchange('node-purge-fanout', {type: 'fanout', confirm: true});
  var q = connection.queue('node-purge-queue', function() {
    q.bind(e, "*");
    q.on('queueBindOk', function() {
      puts("publishing 1 json message");

      e.publish('ackmessage.json1', { name: 'A' }, {}, function() {

        puts('Purge queue');
        q.purge().addCallback(function(ok){
          puts('Deleted '+ok.messageCount+' message');
          assert.equal(1,ok.messageCount);
          puts("publishing another json message");
          e.publish('ackmessage.json2', { name: 'B' });
        });

        q.on('basicConsumeOk', function () {
          setTimeout(function () {
            // wait one second to receive the message, then quit
            connection.end();
          }, 1000);
        });

        q.subscribe({ ack: true }, function (json) {
          recvCount++;
          puts('Got message ' + JSON.stringify(json));
          if (recvCount == 1) {
            assert.equal('B', json.name);
            q.shift();
           } else {
            throw new Error('Too many message!');
           }
        });
      });
    });
  });
});


process.addListener('exit', function () {
  assert.equal(1, recvCount);
});
