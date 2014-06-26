/*
 * client.js: Base client from which all pkgcloud clients inherit from
 *
 * (C) 2013 Nodejitsu Inc.
 *
 */

var fs = require('fs'),
    events = require('eventemitter2'),
    request = require('request'),
    utile = require('utile'),
    qs = require('qs'),
    common = require('../../common'),
    pkgcloud = require('../../../pkgcloud'),
    errs = require('errs');

/**
 * Client
 *
 * @description base Client from which all pkgcloud clients inherit
 *
 * @param {object}    options   options are stored as client.config
 * @type {Function}
 */
var Client = exports.Client = function (options) {
  events.EventEmitter2.call(this, { delimiter: '::', wildcard: true });
  this.config = options || {};
};

utile.inherits(Client, events.EventEmitter2);

/**
 * Client._request
 *
 * @description is the global request handler for a pkgcloud client request.
 * Some clients can override this function, for example
 * rackspace and openstack providers implement an inline authentication mechanism.
 *
 * @param {object}          options     options for this client request
 * @param {Function}        callback    the callback for the client request
 * @private
 */
Client.prototype._request = function (options, callback) {
  var self = this;
  var requestOptions = {};

  requestOptions.method = options.method || 'GET';
  requestOptions.headers = options.headers || {};
  requestOptions.path = options.path;
  requestOptions.strictSSL = typeof self.config.strictSSL === 'boolean'
    ? self.config.strictSSL : true;

  if (options.qs) {
    requestOptions.qs = options.qs;
  }

  if (options.body) {
    requestOptions.body = options.body;
  }

  if (options.container) {
    requestOptions.signingUrl = '/' + options.container + '/';

    if (options.path) {
      requestOptions.signingUrl += options.path;
    }

    if (options.qs) {
      requestOptions.signingUrl += '?' + qs.stringify(options.qs);
    }
  }
  
  function sendRequest(opts) {

    //
    // Setup any specific request options before
    // making the request
    //
    if (self.before) {
      var errors = false;
      for (var i = 0; i < self.before.length; i++) {
        var fn = self.before[i];
        try {
          opts = fn.call(self, opts) || opts;
          // on errors do error handling, break.
        } catch (exc) {
          errs.handle(exc, callback);
          errors = true;
          break;
        }
      }
      if (errors) {
        return;
      }
    }

    opts.uri = options.uri || self._getUrl(options);

    // Clean up our polluted options
    //
    // TODO refactor the options used in Before methods
    // to not require polluting request options
    //
    delete opts.path;
    delete opts.signingUrl;

    // Set our User Agent
    opts.headers['User-Agent'] = utile.format('nodejs-pkgcloud/%s', pkgcloud.version);

    // If we are missing callback
    if (!callback) {
      try {
        self.emit('log::trace', 'Sending (non-callback) client request', opts);
        return request(opts);
      } // if request throws still return an EE
      catch (exc1) {
        self.emit('log::trace', 'Unable to create (non-callback) request', opts);
        return errs.handle(exc1);
      }
    } else {
      try {
        self.emit('log::trace', 'Sending client request', opts);
        self.emit('log::debug', opts.method + ': ' + opts.uri);
        return request(opts, self._defaultRequestHandler(callback));
      } catch (exc2) {
        self.emit('log::error', 'Unable to create request', opts);
        return errs.handle(exc2, callback);
      }
    }
  }

  return sendRequest(requestOptions);
};

/**
 * Client._defaultRequestHandler
 *
 * @description handles requests for all calls
 *
 * @param callback
 * @returns {Function}
 * @private
 */
Client.prototype._defaultRequestHandler = function (callback) {

  var self = this;

  return function (err, res, body) {
    if (err) {
      return callback(err);
    }

    var statusCode = res.statusCode.toString(),
        err2;

    if (Object.keys(self.failCodes).indexOf(statusCode) !== -1) {
      //
      // TODO: Support more than JSON errors here
      //
      err2 = {
        provider: self.provider,
        failCode: self.failCodes[statusCode],
        statusCode: res.statusCode,
        message: self.provider + ' Error (' +
          statusCode + '): ' + self.failCodes[statusCode],
        href: res.request.uri.href,
        method: res.request.method,
        headers: res.headers
      };

      try {
        err2.result = typeof body === 'string' ? JSON.parse(body) : body;
      } catch (e) {
        err2.result = { err: body };
      }

      self.emit('log::error', 'Error during provider response', err2);
      return callback(errs.create(err2));
    }

    self.emit('log::trace', 'Provider Response', {
      href: res.request.uri.href,
      method: res.request.method,
      headers: res.headers,
      statusCode: res.statusCode
    });

    callback(err, body, res);
  }
};
