testLog = function(name, message) { console.log("Test case: "+name+":", message); };
assert =  require('assert');
amqp = require('../amqp');

var options = global.options || {};
if (process.argv[2]) {
  var server = process.argv[2].split(':');
  if (server[0]) options.host = server[0];
  if (server[1]) options.port = parseInt(server[1]);
}

options.host = [options.host,"nohost"];

var implOpts = {
  defaultExchangeName: 'amq.topic'
};

var callbackCalled = false;
    
var connection;

callbackCalled = false;

connection = amqp.createConnection(options, implOpts);

connection.on('ready', function() {
    connection.destroy();
});





