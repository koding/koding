require('coffee-script').register();

var argv     = require('minimist')(process.argv);

// require('./lib/source-server')
module.exports = require('./lib/server');

