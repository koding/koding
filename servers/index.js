require('coffee-script').register();

var argv     = require('minimist')(process.argv);
var newrelic = argv['disable-newrelic'] ? {} : require('newrelic');


// require('./lib/source-server')
module.exports = require('./lib/server');

