'use strict';

var DEBUG = process.env['NODE_DEBUG_AMQP'];

module.exports = function debug () {
  if (DEBUG) console.error.apply(null, arguments);
};

