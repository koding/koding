'use strict';
var Connection = require('./lib/connection');
    
module.exports = {
  Connection: Connection,
  createConnection: function (options, implOptions, readyCallback) {
    var c = new Connection(options, implOptions, readyCallback);
    c.connect();
    return c;
  }
};