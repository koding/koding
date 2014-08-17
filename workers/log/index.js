var argv = require('minimist')(process.argv);
var newrelic = argv['disable-newrelic'] ? {} : require('newrelic');

require('coffee-script').register();
module.exports = require('./lib/log/main.coffee');
