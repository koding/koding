require('coffee-script');
exports.server = require('./lib/server');

// This exposes the bare browserchannel implementation.
//exports.goog = require('./dist/node-browserchannel.js');

var BCSocket = require('./dist/node-bcsocket.js');
exports.BCSocket = BCSocket.BCSocket;
exports.setDefaultLocation = BCSocket.setDefaultLocation;
