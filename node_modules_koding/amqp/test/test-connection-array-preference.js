require('./harness');

options.host = [options.host, "nohost"];

implOpts.reconnect = false;

//If we specify a number bigger than the array, amqp.js will just use the last element in the array
for (var i = 0; i < 3; i++){
  createConnection(i);
}

function createConnection(i){
  var connection;
  var connectionOptions = options;
  connectionOptions.hostPreference = i;
  
  console.log("Connecting to host " + i + " " + options.host[i]);
  connection = amqp.createConnection(connectionOptions, implOpts);
  
  connection.on('error', function() {
    console.log('err');
  });
  connection.on('ready', function() {
    console.log('connected');
    connection.destroy();
  });
}



