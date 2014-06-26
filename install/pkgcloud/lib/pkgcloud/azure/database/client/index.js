/*
 * client.js: Database client for Azure Tables Cloud Databases
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
  azure.Client.call(this, options);

  this.serversUrl = options.serversUrl || azureApi.TABLES_ENDPOINT;

  // add the auth keys for request authorization
  this.azureKeys = {};
  this.azureKeys.storageAccount = this.config.storageAccount;
  this.azureKeys.storageAccessKey = this.config.storageAccessKey;

  this.before.push(auth.azure.tablesSignature);
  utile.mixin(this, require('./databases'));
};

utile.inherits(Client, azure.Client);

//
// Gets the version of the Azure Tables API we are running against
// Parameters: callback
//
Client.prototype.getVersion = function getVersion(callback) {
  return callback(null, azureApi.TABLES_API_VERSION);
};

Client.prototype._getUrl = function (options) {
  options = options || {};

  return urlJoin('http://' + this.azureKeys.storageAccount + '.' + this.serversUrl + '/',
    (typeof options === 'string'
      ? options
      : options.path));
};

Client.prototype._xmlRequest = function query(options, callback) {
  return this._request(options, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    xml2JSON(body, function (err, data) {
      return err
        ? callback(err)
        : callback(err, data, res);
    });
  });
};

// Function formatResponse
// This function parse the response from the provider and return an object
// with the correct keys and values.
// ### @response {Object} The body response from the provider api
Client.prototype.formatResponse = function (response) {
  var database = {
    id: response.content['m:properties']['d:TableName'],
    host: this._getUrl(),
    uri: response.id,
    username: '',
    password: ''
  };
  return database;
};

