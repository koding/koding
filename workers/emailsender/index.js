require('coffee-script').register();
module.exports = require('./main.coffee');

var argv     = require('minimist')(process.argv);
var newrelic = argv['disable-newrelic'] ? {} : require('newrelic');
