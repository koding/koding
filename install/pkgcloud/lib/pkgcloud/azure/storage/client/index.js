/*
 * client.js: Storage client for Azure
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var utile = require('utile'),
    urlJoin = require('url-join'),
    auth = require('../../../common/auth'),
    azureApi = require('../../utils/azureApi.js'),
    xml2JSON = require('../../utils/xml2json.js').xml2JSON,
    azure = require('../../client');

var Client = exports.Client = function (options) {
  this.serversUrl = options.serversUrl || azureApi.STORAGE_ENDPOINT;

  azure.Client.call(this, options);

  utile.mixin(this, require('./containers'));
  utile.mixin(this, require('./files'));

  // add the auth keys for request authorization
  this.azureKeys = {};
  this.azureKeys.storageAccount = this.config.storageAccount;
  this.azureKeys.storageAccessKey = this.config.storageAccessKey;

  this.before.push(auth.azure.storageSignature);
};

utile.inherits(Client, azure.Client);

Client.prototype._xmlRequest = function query(options, callback) {
  return this._request(options, function (err, body, res) {
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

Client.prototype._getUrl = function (options) {
  options = options || {};

  var fragment = '';

  if (options.container) {
    fragment = options.container;
  }

  if (options.path) {
    fragment = urlJoin(fragment, options.path);
  }


  return urlJoin('http://' + this.azureKeys.storageAccount + '.' + this.serversUrl + '/',
    fragment);
};
