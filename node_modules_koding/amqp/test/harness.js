require('longjohn');
var _ = require('lodash');

// Parse incoming options.
var optimist = require('optimist')
  .usage('Run a test.\nUsage: $0')
  .alias('h', 'host')
  .describe('h', 'Specify a hostname to connect to.')
  .default('h', 'localhost')
  .alias('p', 'port')
  .describe('p', 'Specify a port to connect to.')
  .default('p', 5672)
  .alias('d', 'debug')
  .describe('d', 'Show debug output during test.')
  .default('d', false)
  .describe('help', 'Display this help message.');

var argv = optimist.argv;

if (argv.help) {
  optimist.showHelp();
  process.exit(0);
}

if (argv.debug) {
  process.env['NODE_DEBUG_AMQP'] = true;
}

global.util = require('util');
global.puts = console.log;
global.assert = require('assert');
global.amqp = require('../amqp');
global.options = _.extend(global.options || {}, argv);


global.implOpts = {
  defaultExchangeName: 'amq.topic'
};


var harness = module.exports = {
  createConnection: function(opts, implOpts){
    opts = _.defaults(opts || {}, global.options);
    implOpts = _.defaults(implOpts || {}, global.implOpts);
    return amqp.createConnection(options, implOpts);
  },
  run: function(opts, implOpts) {
    global.connection = harness.createConnection(opts, implOpts);
    global.connection.addListener('error', global.errorCallback);
    global.connection.addListener('close', function (e) {
      console.log('connection closed.');
    });
    return global.connection;
  }

};

global.errorCallback = function(e) {
  throw e;
};
