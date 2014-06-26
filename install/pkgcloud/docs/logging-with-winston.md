## Using pkgcloud logging with Winston

[Winston](https://github.com/flatiron/winston) is a popular modular logging framework for node.js. In this example we create a simple winston transport to log to the console, and then connect it to a client.

```Javascript
var pkgcloud = require('pkgcloud'),
    winston = require('winston');

// setup a simple console winston logger
var logger = new winston.Logger({
  levels: {
    debug: 0,
    verbose: 1,
    info: 3,
    warn: 4,
    error: 5
  },
  colors: {
    debug: 'grey',
    verbose: 'cyan',
    info: 'green',
    warn: 'yellow',
    error: 'red'
  },
  transports: [
    new winston.transports.Console({
      level: 'debug',
      prettyPrint: true,
      colorize: true
    })
  ]
});

// setup your client options
var options = {
  username: 'my-user-name',
  password: 'my-password',
  provider: 'rackspace'
};

// create your client
var client = pkgcloud.compute.createClient(options);

// bind logging everything to logger
client.on('log::*', function (message, object) {
  if (object) {
    logger.log(this.event.split('::')[1], message, object);
  }
  else {
    logger.log(this.event.split('::')[1], message);
  }
});

client.getServers(function (err, servers) {
  console.dir(servers);
});

```