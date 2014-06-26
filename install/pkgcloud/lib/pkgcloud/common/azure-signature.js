/*
 * azure-signature.js: Implementation of authentication for Azure APIs.
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var url = require('url'),
  qs = require('querystring'),
  https = require('https'),
  azureApi = require('../azure/utils/azureApi'),
  SharedKey = require('../azure/utils/sharedkey'),
  SharedTableKey = require('../azure/utils/sharedkeytable');

var MANAGEMENT_API_VERSION = azureApi.MANAGEMENT_API_VERSION;
var STORAGE_API_VERSION = azureApi.STORAGE_API_VERSION;

exports.managementSignature = function managementSignature(req, options) {

  req.headers = req.headers || {};
  options = options || {};

  if (!options.key) {
    throw new TypeError('`key` is a required argument for azure-signature');
  }

  if (!options.cert) {
    throw new TypeError('`cert` is a required argument for azure-signature');
  }

  if (typeof options.subscriptionId !== 'string') {
    throw new TypeError('`subscriptionId` is a required argument for azure-signature');
  }

  req.headers['x-ms-version'] =  azureApi.MANAGEMENT_API_VERSION;
  req.headers['accept'] = 'application/xml';
  req.headers['content-type'] = 'application/xml';
};

exports.storageSignature = function storageSignature(req, options) {

  options = options || {};

  if (typeof options.storageAccount !== 'string') {
    throw new TypeError('`storageAccount` is a required argument for azure-signature');
  }

  if (typeof options.storageAccessKey !== 'string') {
    throw new TypeError('`storageAccessKey` is a required argument for azure-signature');
  }

  var sharedKey = new SharedKey(options.storageAccount, options.storageAccessKey);
  sharedKey.signRequest(req);
};

exports.tablesSignature = function tablesSignature(req, options) {

  options = options || {};

  if (typeof options.storageAccount !== 'string') {
    throw new TypeError('`storageAccount` is a required argument for azure-signature');
  }

  if (typeof options.storageAccessKey !== 'string') {
    throw new TypeError('`storageAccessKey` is a required argument for azure-signature');
  }

  var sharedKey = new SharedTableKey(options.storageAccount, options.storageAccessKey);
  sharedKey.signRequest(req);
};
