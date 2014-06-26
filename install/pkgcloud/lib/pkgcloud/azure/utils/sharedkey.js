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
 *
 * derived from azure-sdk-for-node/lib/services/blob/sharedkey.js
 *
 * Modified to sign an Azure request using node request parameters instead of a WebResource
 */

// Module dependencies.
var HeaderConstants = require('./constants').HeaderConstants;
var HmacSha256Sign = require('./hmacsha256sign');
var URL = require('url');
var azureApi = require('./azureApi'),

// Expose 'SharedKey'.
exports = module.exports = SharedKey;

/**
 * Creates a new SharedKey object.
 *
 * @constructor
 * @param {string} storageAccount    The storage account.
 * @param {string} storageAccessKey  The storage account's access key.
 */
function SharedKey(storageAccount, storageAccessKey) {
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
 * @param {req} The request request object.
 * @param {options} The request options to be signed.
 * @param {function (error)}  callback  The callback function.
 * @return {undefined}
 */
SharedKey.prototype.signRequest = function (req, options) {

  var httpVerb = req.method || 'GET';

  req.headers = req.headers || {};
  req.headers['x-ms-date'] = new Date().toUTCString();
  req.headers['x-ms-version'] = HeaderConstants.TARGET_STORAGE_VERSION;

  if (!req.headers[HeaderConstants.CONTENT_LENGTH]) {
    req.headers[HeaderConstants.CONTENT_LENGTH] = '0';
  }

  var stringToSign =
    httpVerb + '\n' +
      getvalueToAppend(req.headers[HeaderConstants.CONTENT_ENCODING]) +
      getvalueToAppend(req.headers[HeaderConstants.CONTENT_LANGUAGE]) +
      getvalueToAppend(req.headers[HeaderConstants.CONTENT_LENGTH]) +
      getvalueToAppend(req.headers[HeaderConstants.CONTENT_MD5]) +
      getvalueToAppend(req.headers[HeaderConstants.CONTENT_TYPE]) +
      getvalueToAppend(req.headers[HeaderConstants.DATE]) +
      getvalueToAppend(req.headers[HeaderConstants.IF_MODIFIED_SINCE]) +
      getvalueToAppend(req.headers[HeaderConstants.IF_MATCH]) +
      getvalueToAppend(req.headers[HeaderConstants.IF_NONE_MATCH]) +
      getvalueToAppend(req.headers[HeaderConstants.IF_UNMODIFIED_SINCE]) +
      getvalueToAppend(req.headers[HeaderConstants.RANGE]) +
      this._getCanonicalizedHeaders(req) +
      this._getCanonicalizedResource(req);

  var signature = this.signer.sign(stringToSign);

  req.headers[HeaderConstants.AUTHORIZATION] = 'SharedKey ' + this.storageAccount + ':' + signature;
};

/*
 * Retrieves the requests's canonicalized resource string.
 * @param {req} request The request to get the canonicalized resource string from.
 * @return {string} The canonicalized resource string.
 */
SharedKey.prototype._getCanonicalizedResource = function (req) {
  var path = '/';
  if (req.path) {
    path = '/' + req.path;
  }

  var canonicalizedResource = '/' + this.storageAccount;

  if (path) {
    canonicalizedResource += path;
  }

  // Get the raw query string values for signing

  if (req.qs) {
    var queryStringValues = req.qs;

    // Build the canonicalized resource by sorting the values by name.
    if (queryStringValues) {
      var paramNames = [];
      for (var n in queryStringValues) {
        paramNames.push(n);
      }

      paramNames = paramNames.sort();
      for (var name in paramNames) {
        canonicalizedResource += '\n' + paramNames[name] + ':' + queryStringValues[paramNames[name]];
      }
    }
  }

  return canonicalizedResource;
};

/*
 * Constructs the Canonicalized Headers string.
 *
 * To construct the CanonicalizedHeaders portion of the signature string,
 * follow these steps: 1. Retrieve all headers for the resource that begin
 * with x-ms-, including the x-ms-date header. 2. Convert each HTTP header
 * name to lowercase. 3. Sort the headers lexicographically by header name,
 * in ascending order. Each header may appear only once in the
 * string. 4. Unfold the string by replacing any breaking white space with a
 * single space. 5. Trim any white space around the colon in the header. 6.
 * Finally, append a new line character to each canonicalized header in the
 * resulting list. Construct the CanonicalizedHeaders string by
 * concatenating all headers in this list into a single string.
 *
 * @param {object} The request object.
 * @return {string} The canonicalized headers.
 */
SharedKey.prototype._getCanonicalizedHeaders = function (req) {
  // Build canonicalized headers
  var canonicalizedHeaders = '';
  if (req.headers) {
    var canonicalizedHeadersArray = [];
    for (var header in req.headers) {
      if (header.indexOf(HeaderConstants.PREFIX_FOR_STORAGE_HEADER) === 0) {
        canonicalizedHeadersArray.push(header);
      }
    }

    canonicalizedHeadersArray.sort();
    for (var headerName in canonicalizedHeadersArray) {
      canonicalizedHeaders += canonicalizedHeadersArray[headerName].toLowerCase() + ":" + req.headers[canonicalizedHeadersArray[headerName]] + '\n';
    }
  }

  return canonicalizedHeaders;
};