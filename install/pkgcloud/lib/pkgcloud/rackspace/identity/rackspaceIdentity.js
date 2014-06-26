/*
 * rackspaceIdentity.js: rackspaceIdentity model
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var _ = require('underscore'),
  identity = require('../../openstack/context'),
  events = require('eventemitter2'),
  Identity = identity.Identity,
  util = require('util');

exports.Identity = RackspaceIdentity = function (options) {
  this.options = options;
  this.name = 'RackspaceIdentity';

  this.useServiceCatalog = (typeof options.useServiceCatalog === 'boolean')
    ? options.useServiceCatalog
    : true;

  events.EventEmitter2.call(this, { delimiter: '::', wildcard: true });
};

util.inherits(RackspaceIdentity, events.EventEmitter2);
util.inherits(RackspaceIdentity, Identity);

RackspaceIdentity.prototype._buildAuthenticationPayload = function () {
  var self = this;

  RackspaceIdentity.super_.prototype._buildAuthenticationPayload.call(this);

  this.emit('log::trace', 'Building Rackspace Identity Auth Payload');

  if (!self._authenticationPayload) {
    // setup our inputs for authorization
    // key & username
    if (self.options.apiKey && self.options.username) {
      self._authenticationPayload = {
        auth: {
          'RAX-KSKEY:apiKeyCredentials': {
            username: self.options.username,
            apiKey: self.options.apiKey
          }
        }
      };
    }
  }
};
