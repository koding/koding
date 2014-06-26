/*
 * client.js: Base client from which all OpenStack clients inherit from
 *
 * (C) 2013 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    request = require('request'),
    through = require('through'),
    base = require('../core/base'),
    errs = require('errs'),
    context = require('./context');

/**
 * Client
 *
 * @description Base client from which all OpenStack clients inherit from,
 * inherits from core.Client
 *
 * @type {Function}
 */
var Client = exports.Client = function (options) {

  var self = this;

  options.earlyTokenTimeout = typeof options.earlyTokenTimeout === 'number'
    ? options.earlyTokenTimeout
    : (1000 * 60 * 5);

  base.Client.call(this, options);

  options.identity = options.identity || context.Identity;

  this.authUrl    = options.authUrl || 'auth.api.trystack.org';
  this.provider   = 'openstack';
  this.region     = options.region;
  this.tenantId     = options.tenantId;

  if (!/^http[s]?\:\/\//.test(this.authUrl)) {
    this.authUrl = 'http://' + this.authUrl;
  }

  if (!this.before) {
    this.before = [];
  }

  this.before.push(function (req) {
    req.headers = req.headers || {};
    req.headers['x-auth-token'] = this._identity ? this._identity.token.id : this.config.authToken;
  });

  this.before.push(function (req) {
    req.json = true;
    if (typeof req.body !== 'undefined') {
      req.headers['Content-Type'] = 'application/json';
    }
  });

  this._identity = new options.identity(this._getIdentityOptions());

  this._identity.on('log::*', function(message, object) {
    self.emit(this.event, message, object);
  });

  this._serviceUrl = null;
};

utile.inherits(Client, base.Client);

Client.prototype._getIdentityOptions = function() {
  var options = {
    url: this.authUrl,
    username: this.config.username,
    password: this.config.password
  };

  if (this.config.tenantId) {
    options.tenantId = this.config.tenantId;
  }
  else if (this.config.tenantName) {
    options.tenantName = this.config.tenantName;
  }
  if (typeof this.config.useServiceCatalog === 'boolean') {
    options.useServiceCatalog = this.config.useServiceCatalog;
  }

  return options;
};

Client.prototype.failCodes = {
  400: 'Bad Request',
  401: 'Unauthorized',
  403: 'Resize not allowed',
  404: 'Item not found',
  409: 'Build in progress',
  413: 'Over Limit',
  415: 'Bad Media Type',
  422: 'Unprocessable Entity',
  500: 'Fault',
  503: 'Service Unavailable'
};

Client.prototype.successCodes = {
  200: 'OK',
  201: 'Created',
  202: 'Accepted',
  203: 'Non-authoritative information',
  204: 'No content'
};

/**
 * Client.auth
 *
 * @description This function handles the primary authentication for OpenStack
 * and, if successful, sets an identity object on the client
 *
 * @param callback
 */
Client.prototype.auth = function (callback) {
  var self = this;

  if (self._isAuthorized()) {
    callback();
    return;
  }

  self._identity.authorize(function(err) {
    if (err) {
      return callback(err);
    }

    var options = {
      region: self.region,
      serviceType: self.serviceType,
      useInternal: self.config.useInternal,
      useAdmin: self.config.useAdmin
    };

    try {
      self._serviceUrl = self._identity.getServiceEndpointUrl(options);

      self.emit('log::trace', 'Selected service url', {
        serviceUrl: self._serviceUrl,
        options: options
      });

      callback();
    }
    catch (e) {
      self.emit('log::error', 'Unable to select endpoint for service', {
        error: e.toString(),
        options: options
      });
      callback(e);
    }
  });
};

/**
 * Client._request
 *
 * @description custom request implementation for supporting inline auth for
 * OpenStack. this allows piping while not yet possessing a valid auth token
 *
 * @param {object}          options     options for this client request
 * @param {Function}        callback    the callback for the client request
 * @private
 */
Client.prototype._request = function (options, callback) {

  var self = this;
  if (!self._isAuthorized()) {
    self.emit('log::trace', 'Not-Authenticated, inlining Auth...');
    var buf = through().pause();
    self.auth(function (err) {
      if (err) {
        self.emit('log::error', 'Error with inline authentication', err);
        return errs.handle(err, callback);
      }

      self.emit('log::trace', 'Creating Authenticated Proxy Request');
      var apiStream = Client.super_.prototype._request.call(self, options, callback);

      if (options.upload) {
        buf.pipe(apiStream);
      }
      else if (options.download) {
        apiStream.pipe(buf);
      }

      buf.resume();
    });

    return buf;
  }
  else {
    self.emit('log::trace', 'Creating Authenticated Request');
    return Client.super_.prototype._request.call(self, options, callback);
  }
};

Client.prototype._isAuthorized = function () {
  var self = this,
      authorized = false;

  if (!self._serviceUrl || !self._identity || !self._identity.token || !self._identity.token.id || !self._identity.token.expires) {
    authorized = false;
  }
  else if (self._identity.token.expires.getTime() - new Date().getTime() > self.config.earlyTokenTimeout) {
    authorized = true;
  }

  return authorized;
};
