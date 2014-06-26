/*
 * auth.js: Utilities for authenticating with multiple cloud providers
 *
 * (C) 2011-2012 Nodejitsu Inc.
 *
 */

var httpSignature = require('./http-signature'),
    awsSignature = require('./aws-signature'),
    azureSignature = require('./azure-signature'),
    utile = require('utile');

var auth = exports;

auth.basic = function basicAuth(req) {
  var credentials = this.credentials
    || this.config.username + ':' + this.config.password;

  req.headers = req.headers || {};
  req.headers.authorization = [
    'Basic',
    utile.base64.encode(credentials)
  ].join(' ');
};

// Add Account number for requests to rackspace API
auth.accountId = function (req) {
  req.headers = req.headers || {};
  req.headers['x-auth-project-id'] = this.config.accountNumber;
};

function signatureGenerator(sign) {
  return function signatureAuth(req, keys) {
    keys = keys || this.config;
    sign.call(this, req, {
      key: keys.key,
      keyId: keys.keyId
    });
  };
}

function azureSignatureGenerator(sign) {
  return function azureSignatureGenerator(req, keys) {
    keys = keys || this.azureKeys;
    sign.call(this, req, keys);
  };
}

auth.httpSignature = signatureGenerator(httpSignature.sign);
auth.amazon = {
  bodySignature: signatureGenerator(awsSignature.signBody),
  headersSignature: signatureGenerator(awsSignature.signHeaders)
};

auth.azure = {
  managementSignature: azureSignatureGenerator(azureSignature.managementSignature),
  storageSignature: azureSignatureGenerator(azureSignature.storageSignature),
  tablesSignature: azureSignatureGenerator(azureSignature.tablesSignature)
};

