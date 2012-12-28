var assert = require('assert');
var amqp = require('../amqp');
var exec = require('child_process').exec;

var options = global.options || {};
if (process.argv[2]) {
  var server = process.argv[2].split(':');
  if (server[0]) options.host = server[0];
  if (server[1]) options.port = parseInt(server[1]);
}

exec('which rabbitmqctl', function(err,res){
  if(err != null){
    process.exit(0);
  }else{
    var implOpts = {
      reconnect: true,
      reconnectBackoffStrategy: 'exponential',
      // A 500ms backoff time with an exponential strategy should cause
      // the following to occur:
      // t = 0     ms server shutdown
      // t = ~0    ms connection severed
      // t = ~500  ms reconnection attempt fails
      // t = ~1500 ms reconnection attempt fails
      // t = ~1500 ms server restarted
      // t = ~3500 ms reconnection attempt succeeds
      reconnectBackoffTime: 500,
    };

    var cycleServer = function (stoppedCallback, startedCallback) {
      // If you're running a cluster you can do this:
      // 'killall -9 beam.smp'
      // to test out hard server fails.  Note however that you probably do want a
      // cluster because killing a single server this way causes even durable
      // queues to be deleted, causing the bindings we create to be removed.
      exec('rabbitmqctl stop_app', function () {
        setTimeout(function () {
          if (stoppedCallback) {
            stoppedCallback();
          }
          // Likewise you can bring up a hard server crash this way:
          // 'rabbitmq-server -detached'
          exec('rabbitmqctl start_app', function () {
            if (startedCallback) {
              setTimeout(startedCallback, 500);
            }
          });
        // Leave the server down for 1500ms before restarting.
        }, 1500);
      });
    }

    var readyCount = 0;
    var errorCount = 0;
    var closeCount = 0;
    var messageCount = 0;

    var runTest = function () {
      console.log("Starting...");
      
      var connection = amqp.createConnection(options, implOpts);
      var exchange = null;
      var queue = null;
      var exit = false;
      var done = function (error) {
        if (exchange) {
          exchange.destroy();
        }
        if (queue) {
          queue.destroy();
        }
        if (error) {
          // Exit loudly.
          console.log('Error: "' + error + '", abandoning test cycle');
          throw error;
        } else {
          console.log('All done!');
          // Exit gracefully.
          connection.setImplOptions({'reconnect': false});
          connection.destroy();
        }
        exit = true;
      }
      var connectionDownTimestamp = null;
      connection.on('ready', function() {
        readyCount += 1;
        console.log('Connection ready (' + readyCount + ')');
        
        if (readyCount === 1) {
          // Create an exchange.  Make it durable, because our test case shuts down the exchange
          // in lieu of interrupting network communications.
          exchange = connection.exchange('node-reconnect-exchange', {type: 'topic', durable: true});
          // Now, create a queue.  Bind it to an exchange, and pump a few messages
          // in to it.  This is just to prove that the queue is working *before*
          // we disconnect it.  Remember to make it durable for the same reason
          // as the exchange.
          connection.queue('node-reconnect-queue', {autoDelete: false, durable: true}, function (q) {
            queue = q;
            queue.on('queueBindOk', function () {
              queue.once('basicConsumeOk', function () {
                exchange.publish('node-reconnect', 'one');
                console.log('Message one published');
                exchange.publish('node-reconnect', 'two');
                console.log('Message two published');
              });
            });
            queue.bind(exchange, '#');
            queue.subscribe(function (message) {
              messageCount += 1;
              console.log('Message received (' + messageCount + '): ' + message.data);
              if (messageCount === 2) {
                // On the second message, restart the server.
                cycleServer(function () {
                  // Don't wait for it to come back up, publish a message while it is down.
                  exchange.publish('node-reconnect', 'three');
                  console.log('Message three published');
                });
              } else if (messageCount === 4) {
                return done();
              }
            });
          });
        } else if (readyCount === 2) {
          // Ensure that the backoff timeline is approximately correct.  We
          // expect a 500ms backoff, followed by a 1000ms backoff, followed
          // by a 2000ms backoff, resulting in about 3500ms of disconnected
          // time.
          var disconnectionTime = (Date.now() - connectionDownTimestamp);
          console.log('connection down for ' + disconnectionTime + ' ms');
          assert(disconnectionTime >= 3500);
          // Allow some grace period for processing and transit, but the tests
          // are all done on localhost, so not *too* much.
          assert(disconnectionTime <= 3700)
          // Ensure we get the rest of the messages from the queue.  This means
          // that the connection and queue were automatically reconnected with
          // no user interaction, and no messages were lost.
          // Publish another message after the connection has been restored.
          exchange.publish('node-reconnect', 'four');
          console.log('Message four published');
        }
      });
      connection.on('error', function (error) {
        errorCount += 1;
        console.log('Connection error (' + errorCount + '): ' + error);
        if (connectionDownTimestamp === null) {
          connectionDownTimestamp = Date.now();
        }
      });
      connection.on('close', function () {
        closeCount += 1;
        console.log('Connection close (' + closeCount + ')');
        if (connectionDownTimestamp === null) {
          connectionDownTimestamp = Date.now();
        }
      });
      var waitForExitConditions = function () {
        if (!exit) {
          setTimeout(waitForExitConditions, 500);
        }
      }
      waitForExitConditions();
    };

    runTest();

    process.addListener('exit', function () {
      // 1 ready on initial connection, 1 on reconnection
      assert.equal(2, readyCount);
      // 4 messages sent and received
      assert.equal(4, messageCount);
    });
  }
})

