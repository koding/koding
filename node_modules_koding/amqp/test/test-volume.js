var amqp = require('../amqp');
var proxy = require('./proxy');

var options = global.options || {};
if (process.argv[2]) {
  var server = process.argv[2].split(':');
  if (server[0]) options.host = server[0];
  if (server[1]) options.port = parseInt(server[1]);
}

var implOpts = {
  reconnect: true,
  reconnectBackoffStrategy: 'linear',
  reconnectBackoffTime: 100,
};

// How many messages to send?
var MESSAGE_COUNT = 1000;
// How many messages can we afford to lose and still pass?
var MESSAGE_GRACE = 10;
// How many milliseconds between proxy kills?
var INTERRUPT_INTERVAL = 300;
// How many milliseconds between message sends?
var MESSAGE_INTERVAL = 1;

var runTest = function () {
  console.log("Starting...");

  var exit = false;
  var done = function (error) {
    if (!exit) {
      if (exchange) {
        exchange.destroy();
        exchange = null;
      }
      if (queue) {
        queue.destroy();
        queue = null;
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
    }
    exit = true;
  };
  var timeout = setTimeout(function () {
    return done(new Error('Time expired without success'));
  }, 5000);

  // Proxy our connection to RabbitMQ through a local port which we can interrupt at will.
  var proxyRoute = new proxy.route(9001, options.port, options.host);
  var interrupter = setInterval(function () {
    proxyRoute.interrupt();
  }, INTERRUPT_INTERVAL);
  options.host = '127.0.0.1';
  options.port = 9001;
  // Connect to the proxy
  var connection = amqp.createConnection(options, implOpts);
  var exchange = null;
  var queue = null;
  var messageCount = 0;
  connection.once('ready', function () {
    // Create an exchange.
    exchange = connection.exchange('node-volume-exchange', {type: 'topic'});
    // Now, create a queue.  Bind it to an exchange, and pump a lot of
    // messages in to it.
    connection.queue('node-volume-queue', {autoDelete: false}, function (q) {
      queue = q;
      queue.on('queueBindOk', function () {
        queue.once('basicConsumeOk', function () {
          var counter = 0;
          var interval = setInterval(function () {
            counter += 1;
            exchange.publish('node-volume', 'this is message ' + counter);
            console.log('Message ' + counter + ' published');
            if (counter === MESSAGE_COUNT) {
              clearInterval(interval);
              interval = null;
            }
          }, MESSAGE_INTERVAL);
        });
      });
      queue.bind(exchange, '#');
      // We could use acks to lose even fewer messages but since we're not
      // using publisher confirms, we'll likely lose a few from the other
      // side, so let's not bother.
      // queue.subscribe({'ack': true}, function (message) {
      //   ...
      //   queue.shift();
      // });
      queue.subscribe(function (message) {
        messageCount += 1;
        console.log('Message received (' + messageCount + '): ' + message.data);
        if (messageCount === MESSAGE_COUNT) {
          return done();
        } else if (messageCount + MESSAGE_GRACE === MESSAGE_COUNT) {
          setTimeout(done, 500);
        }
      });
    });
  });

  connection.on('ready', function() {
    // Just an FYI message
    console.log('Connection ready');
  });
  connection.on('error', function (error) {
    // Just an FYI message
    console.log('Connection error: ' + error);
  });
  connection.on('close', function (hadError) {
    // Just an FYI message
    console.log('Connection close' + (hadError ? ' because of error' : ''));
  });

  var waitForExitConditions = function () {
    if (!exit) {
      setTimeout(waitForExitConditions, 500);
    } else {
      // Kill everything which would keep this test from exiting.
      if (interrupter) {
        clearInterval(interrupter);
        interrupter = null;
      }
      if (proxyRoute) {
        proxyRoute.close();
        proxyRoute = null;
      }
      if (timeout) {
        clearTimeout(timeout);
        timeout = null;
      }
    }
  }
  waitForExitConditions();
};

runTest();