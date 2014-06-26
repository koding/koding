/*
 * index.js: Rackspace DNS client
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    rackspace = require('../../client'),
    urlJoin = require('url-join'),
    Status = require('../status').Status,
    _ = require('underscore');

var Client = exports.Client = function (options) {
  rackspace.Client.call(this, options);

  utile.mixin(this, require('./records.js'));
  utile.mixin(this, require('./zones.js'));

  this.serviceType = 'rax:dns';
};

utile.inherits(Client, rackspace.Client);

Client.prototype._getUrl = function (options) {
  options = options || {};

  var fragment = '';

  if (options.path) {
    fragment = urlJoin(fragment, options.path);
  }

  if (fragment === '' || fragment === '/') {
    return this._serviceUrl;
  }

  return urlJoin(this._serviceUrl, fragment);
};

Client.prototype._asyncRequest = function(options, callback) {
  var self = this;

  self._request(options, function (err, body) {
    if (err) {
      return callback(err);
    }

    var status = new Status(self, body);

    status.setWait(function (details) {
      return (details.status !== 'RUNNING' && details.status !== 'INITIALIZED');
    }, 1000, 30000, function (err, results) {

      return err
        ? callback(err)
        : results.error
        ? callback(results.error)
        : callback(err, results);
    });
  });
};