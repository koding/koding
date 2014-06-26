/*
 * hpIdentity.js: hpIdentity model
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 * Phani Raj
 *
 */

var _ = require('underscore'),
  identity = require('../../openstack/context'),
  events = require('eventemitter2'),
  Identity = identity.Identity,
  util = require('util');

exports.Identity = HPIdentity = function (options) {
  this.options = options;
  this.name = 'HPIdentity';

  this.useServiceCatalog = (typeof options.useServiceCatalog === 'boolean')
    ? options.useServiceCatalog
    : true;

  events.EventEmitter2.call(this, { delimiter: '::', wildcard: true });
};

util.inherits(HPIdentity, events.EventEmitter2);
util.inherits(HPIdentity, Identity);

HPIdentity.prototype._buildAuthenticationPayload = function () {
  var self = this;

  HPIdentity.super_.prototype._buildAuthenticationPayload.call(this);

  this.emit('log::trace', 'Building HP Identity Auth Payload');

  if (!self._authenticationPayload) {
    // setup our inputs for authorization
    // access key & secret key
    if (self.options.apiKey && self.options.username) {
      self._authenticationPayload = {
        auth: {
          'apiAccessKeyCredentials': {
            'accessKey': self.options.username,
            'secretKey': self.options.apiKey
          }
        }
      };
    }
  }
};
