/*
 * index.js: Compute client for Azure
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var qs = require('querystring'),
    utile = require('utile'),
    urlJoin = require('url-join'),
    https = require('https'),
    auth = require('../../../common/auth'),
    azureApi = require('../../utils/azureApi.js'),
    xml2JSON = require('../../utils/xml2json.js').xml2JSON,
    azure = require('../../client');

var Client = exports.Client = function (options) {
  azure.Client.call(this, options);

  utile.mixin(this, require('./flavors'));
  utile.mixin(this, require('./images'));
  utile.mixin(this, require('./servers'));
  utile.mixin(this, require('./keys'));

  this.serversUrl = options.serversUrl || azureApi.MANAGEMENT_ENDPOINT;
  this.version = azureApi.MANAGEMENT_API_VERSION;
  this.subscriptionId = this.config.subscriptionId;

  this.azureKeys = {
    key: this.config.key,
    cert: this.config.cert
  };

  this.azureKeys.subscriptionId = this.config.subscriptionId;

  this.before.push(auth.azure.managementSignature);

  // The https agent is used by request for authenticating TLS/SSL https calls
  if (this.protocol === 'https://') {
    this.before.push(function (req) {
      req.agent = new https.Agent({
        host: this.serversUrl,
        key: options.key,
        cert: options.cert
      });
    });
  }
};

utile.inherits(Client, azure.Client);

Client.prototype._query = function query(action, query, callback) {
  return this._request({
    method: 'POST',
    headers: { },
    body: utile.mixin({ Action: action }, query)
  }, function (err, body, res) {
    if (err) { return callback(err); }
    xml2JSON(body, function (err, data) {
      return err
        ? callback(err)
        : callback(data, res);
    });
  });
};

Client.prototype.get = function get(action, callback) {
  return this._request({ path: action }, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    xml2JSON(body, function (err, data) {
      return err
        ? callback(err)
        : callback(null, data, res);
    });
  });
};

Client.prototype._xmlRequest = function query(options, callback) {

  return this._request(options, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    xml2JSON(body, function (err, data) {
      return err ?
        callback(err) :
        callback(null, data, res);
    });
  });
};

Client.prototype._getUrl = function (options) {
  options = options || {};

  return urlJoin(this.protocol + this.serversUrl + '/',
    (typeof options === 'string'
      ? options
      : options.path));
};


