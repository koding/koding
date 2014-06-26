/*
 * identity.js: Identity for openstack authentication
 *
 * (C) 2013 Rackspace, Ken Perkins
 * MIT LICENSE
 *
 */

var _ = require('underscore'),
    events = require('eventemitter2'),
    fs = require('fs'),
    request = require('request'),
    ServiceCatalog = require('./serviceCatalog').ServiceCatalog,
    svcCat = require('./serviceCatalog'),
    url = require('url'),
    utile = require('utile'),
    urlJoin = require('url-join'),
    util = require('util'),
    pkgcloud = require('../../../pkgcloud'),
    errs = require('errs');

// TODO refactor failCodes, getError into global handlers
var failCodes = {
  400: 'Bad Request',
  401: 'Unauthorized',
  403: 'Resize not allowed',
  404: 'Item not found',
  405: 'Bad Method',
  409: 'Build in progress',
  413: 'Over Limit',
  415: 'Bad Media Type',
  500: 'Fault',
  503: 'Service Unavailable'
};

/**
 * Identity object
 *
 * @description Base Identity object for Openstack Keystone
 *
 * @param options
 * @constructor
 */
var Identity = exports.Identity = function (options) {
  var self = this;

  events.EventEmitter2.call(this, { delimiter: '::', wildcard: true });

  self.options = options || {};
  self.name = 'OpenstackIdentity';
  self.useServiceCatalog = (typeof options.useServiceCatalog === 'boolean')
    ? options.useServiceCatalog
    : true;

  _.each(['url'], function (value) {
    if (!self.options[value]) {
      throw new Error('options.' + value + ' is a required option');
    }
  });
};

utile.inherits(Identity, events.EventEmitter2);

/**
 * Identity.authorize
 *
 * @description this function is the guts of authorizing against an openstack
 * identity endpoint.
 * @param {object}  options   the options for authorization
 * @param callback
 */
Identity.prototype.authorize = function (options, callback) {
  var self = this;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  var authenticationOptions = {
    uri: urlJoin(options.url || self.options.url, '/v2.0/tokens'),
    method: 'POST',
    headers: {
      'User-Agent': util.format('nodejs-pkgcloud/%s', pkgcloud.version),
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }
  };

  self._buildAuthenticationPayload();

  // we can't be called without a payload
  if (!self._authenticationPayload) {
    return process.nextTick(function () {
      callback(new Error('Unable to authorize; missing required inputs'));
    });
  }

  // Are we filtering down by a tenant?
  if (self.options.tenantId) {
    self._authenticationPayload.auth.tenantId = self.options.tenantId;
  }
  else if (self.options.tenantName) {
    self._authenticationPayload.auth.tenantName = self.options.tenantName;
  }

  authenticationOptions.json = self._authenticationPayload;

  self.emit('log::trace', 'Sending client authorization request', authenticationOptions);

  // Don't keep a copy of the credentials in memory
  delete self._authenticationPayload;

  request(authenticationOptions, function (err, response, body) {
    // check for a network error, or a handled error
    var err2 = getError(err, response, body);

    if (err2) {
      return callback(err2);
    }

    self.emit('log::trace', 'Provider Authentication Response', {
      href: response.request.uri.href,
      method: response.request.method,
      headers: response.headers,
      statusCode: response.statusCode
    });

    // If we don't have a tenantId in the response (meaning no service catalog)
    // go ahead and make a 1-off request to get a tenant and then reauthorize
    if (!body.access.token.tenant) {
      getTenantId(urlJoin(options.url || self.options.url, '/v2.0/tenants'), body.access.token.id);
    }
    else {
      try {
        self._parseIdentityResponse(body);
        callback();
      }
      catch (e) {
        callback(e);
      }
    }
  });

  function getTenantId(endpoint, token) {
    var tenantOptions = {
      uri: endpoint,
      json: true,
      headers: {
        'X-Auth-Token': token,
        'Content-Type': 'application/json',
        'User-Agent': util.format('nodejs-pkgcloud/%s', pkgcloud.version)
      }
    };

    request(tenantOptions, function (err, response, body) {
      if (err || !body.tenants || !body.tenants.length) {
        return callback(err ? err : new Error('Unable to find tenants'));
      }

      var firstActiveTenant;
      body.tenants.forEach(function (tenant) {
        if (!firstActiveTenant && !!tenant.enabled && tenant.enabled !== 'false') {
          firstActiveTenant = tenant;
        }
      });

      if (!firstActiveTenant) {
        return callback(new Error('Unable to find an active tenant'));
      }

      // TODO make this more resiliant (what if multiple active tenants)
      self.options.tenantId = firstActiveTenant.id;
      self.authorize(options, callback);
    });
  }
};

/**
 * Identity._buildAuthenticationPayload
 *
 * @description processes the authentication options into a valid payload for
 * authorization
 *
 * @private
 */
Identity.prototype._buildAuthenticationPayload = function () {
  var self = this;

  self.emit('log::trace', 'Building Openstack Identity Auth Payload');

  // setup our inputs for authorization
  if (self.options.password && self.options.username) {
    self._authenticationPayload = {
      auth: {
        passwordCredentials: {
          username: self.options.username,
          password: self.options.password
        }
      }
    };
  }
  // Token and tenant are also valid inputs
  else if (self.options.token && (self.options.tenantId || self.options.tenantName)) {
    self._authenticationPayload = {
      auth: {
        token: {
          id: self.options.token
        }
      }
    };
  }
};

/**
 * Identity._parseIdentityResponse
 *
 * @description takes the full identity response and deserializes it into a
 * serviceCatalog object with services.
 *
 * @param {object}    data      the raw response from the identity call
 * @private
 */
Identity.prototype._parseIdentityResponse = function (data) {
  var self = this;

  if (!data) {
    throw new Error('missing required arguments!');
  }
  
  if (data.access.token) {
    self.token = data.access.token;
    self.token.expires = new Date(self.token.expires);
  }

  if (self.useServiceCatalog && data.access.serviceCatalog) {
     self.serviceCatalog = new ServiceCatalog(data.access.serviceCatalog);
  }

  self.user = data.access.user;
  self.raw = data;

};

Identity.prototype.getServiceEndpointUrl = function (options) {
  if (this.useServiceCatalog) {
    return this.serviceCatalog.getServiceEndpointUrl(options);
  }
  else {
    return this.options.url;
  }
};


function getError(err, res, body) {
  if (err) {
    return err;
  }

  var statusCode = res.statusCode.toString(),
    err2;

  if (Object.keys(failCodes).indexOf(statusCode) !== -1) {
    //
    // TODO: Support more than JSON errors here
    //
    err2 = {
      failCode: failCodes[statusCode],
      statusCode: res.statusCode,
      message: 'Error (' +
        statusCode + '): ' + failCodes[statusCode],
      href: res.request.uri.href,
      method: res.request.method,
      headers: res.headers
    };

    try {
      err2.result = typeof body === 'string' ? JSON.parse(body) : body;
    } catch (e) {
      err2.result = { err: body };
    }

    return err2;
  }

  return;
}
