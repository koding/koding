var argv     = require('minimist')(process.argv);

require('coffee-script').register();
module.exports = require('./lib/social/main.coffee');
