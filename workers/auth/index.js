require('coffee-script').register();
module.exports = require('./lib/auth/main');

var argv     = require('minimist')(process.argv);
var newrelic = argv['disable-newrelic'] ? {} : require('newrelic');

