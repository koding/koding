// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var Client = require('./client');
var Attribute = require('./attribute');
var Change = require('./change');
var Protocol = require('./protocol');
var Server = require('./server');

var assert = require('assert');
var controls = require('./controls');
var dn = require('./dn');
var errors = require('./errors');
var filters = require('./filters');
var logStub = require('./log_stub');
var messages = require('./messages');
var schema = require('./schema');
var url = require('./url');



/// Hack a few things we need (i.e., "monkey patch" the prototype)

if (!String.prototype.startsWith) {
  String.prototype.startsWith = function(str) {
    var re = new RegExp('^' + str);
    return re.test(this);
  };
}


if (!String.prototype.endsWith) {
  String.prototype.endsWith = function(str) {
    var re = new RegExp(str + '$');
    return re.test(this);
  };
}



///--- API

module.exports = {

  Client: Client,
  createClient: function(options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options (object) required');

    return new Client(options);
  },

  Server: Server,
  createServer: function(options) {
    return new Server(options);
  },

  Attribute: Attribute,
  Change: Change,

  DN: dn.DN,
  RDN: dn.RDN,
  parseDN: dn.parse,
  dn: dn,

  filters: filters,
  parseFilter: filters.parseString,

  log4js: logStub,
  parseURL: url.parse,
  url: url,

  loadSchema: schema.load,
  createSchemaAddHandler: schema.createAddHandler,
  createSchemaModifyHandler: schema.createModifyHandler,
  createSchemaSearchHandler: schema.createSearchHandler
};



///--- Export all the childrenz

var k;

for (k in Protocol) {
  if (Protocol.hasOwnProperty(k))
    module.exports[k] = Protocol[k];
}

for (k in messages) {
  if (messages.hasOwnProperty(k))
    module.exports[k] = messages[k];
}

for (k in controls) {
  if (controls.hasOwnProperty(k))
    module.exports[k] = controls[k];
}

for (k in filters) {
  if (filters.hasOwnProperty(k)) {
    if (k !== 'parse' && k !== 'parseString')
      module.exports[k] = filters[k];
  }
}

for (k in errors) {
  if (errors.hasOwnProperty(k)) {
    module.exports[k] = errors[k];
  }
}
