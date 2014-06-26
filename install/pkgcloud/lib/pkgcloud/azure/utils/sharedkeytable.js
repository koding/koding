/**
 * Copyright (c) Microsoft.  All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Module dependencies.
var HmacSha256Sign = require('./hmacsha256sign'),
    HeaderConstants = require('./constants').HeaderConstants,
    azureApi = require('../utils/azureApi'),
    URL = require('url');

// Expose 'SharedKeyTable'.
exports = module.exports = SharedKeyTable;

/**
 * Creates a new SharedKeyTable object.
 *
 * @constructor
 * @param {string} storageAccount    The storage account.
 * @param {string} storageAccessKey  The storage account's access key.
 */
function SharedKeyTable(storageAccount, storageAccessKey) {
  this.storageAccount = storageAccount;
  this.storageAccessKey = storageAccessKey;
  this.signer = new HmacSha256Sign(storageAccessKey);
}

var getvalueToAppend = function (value) {
  return value ? value + '\n' : '\n';
};

/**
 * Signs a request with the Authentication header.
 *
 * @param {req} req The request to be signed.
 * @return {undefined}
 */
SharedKeyTable.prototype.signRequest = function (req) {

  var httpVerb = req.method || 'GET',
    signature;

  req.headers['x-ms-date'] = new Date().toUTCString();
  req.headers['x-ms-version'] = azureApi.TABLES_API_VERSION;
  req.headers['content-type'] = 'application/atom+xml;charset="utf-8"';
  req.headers['accept'] = 'application/atom+xml;charset="utf-8"';

  if (!req.headers[HeaderConstants.CONTENT_LENGTH]) {
    req.headers[HeaderConstants.CONTENT_LENGTH] = '0';
  }

  var stringToSign =
    httpVerb + '\n' +
      getvalueToAppend(req.headers[HeaderConstants.CONTENT_MD5]) +
      getvalueToAppend(req.headers[HeaderConstants.CONTENT_TYPE]) +
      getvalueToAppend(req.headers[HeaderConstants.DATE_HEADER]) +
      this._getCanonicalizedResource(req);

  req.headers['DataServiceVersion'] = '1.0;NetFx';
  req.headers['MaxDataServiceVersion'] = '2.0;NetFx';
  signature = this.signer.sign(stringToSign);

  req.headers[HeaderConstants.AUTHORIZATION] = 'SharedKey ' + this.storageAccount + ':' + signature;
};

/*
 * Retrieves the requests's canonicalized resource string.
 * @param {req} req The request to get the canonicalized resource string from.
 * @return {string} The canonicalized resource string.
 */
SharedKeyTable.prototype._getCanonicalizedResource = function (req) {
  var path = '/';
  if (req.path[0]) {
    path = '/' + req.path[0];
  }

  var canonicalizedResource = '/' + this.storageAccount;

  if (path) {
    canonicalizedResource += path;
  }

  if (req.path.length > 1) {
    var u = URL.parse(req.path[1], true);
    var queryStringValues = u.query;

    if (queryStringValues) {
      if (queryStringValues['comp']) {
        canonicalizedResource += '?comp=' + queryStringValues['comp'];
      }
    }
  }
  return canonicalizedResource;
};