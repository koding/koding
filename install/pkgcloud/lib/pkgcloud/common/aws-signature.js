/*
 * aws-signature.js: Implmentation of authentication for Amazon AWS APIs.
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var url = require('url'),
    qs = require('querystring'),
    crypto = require('crypto');

exports.signBody = function signBody(req, options) {
  if (!options) options = {};

  if (typeof options.key !== 'string') {
    throw new TypeError('`key` is a required argument for aws-signature');
  }

  if (typeof options.keyId !== 'string') {
    throw new TypeError('`keyId` is a required argument for aws-signature');
  }

  var signatureString = [
        req.method, '\n',
        this.serversUrl, '\n',
        '/', '\n'
      ],
      query = req.body;

  query.AWSAccessKeyId = options.keyId;
  query.SignatureMethod = 'HmacSHA256';
  query.SignatureVersion = 2;
  query.Version = this.version;
  query.Timestamp = new Date(+new Date + 36e5 * 30).toISOString();

  Object.keys(query).sort().forEach(function (key, i) {
    if (i !== 0) signatureString.push('&');
    signatureString.push(encodeURIComponent(key), '=', encodeURIComponent(query[key]));
  });

  var toSign = signatureString.join('');

  // Crappy code, but AWS seems to need it
  toSign = toSign.replace(/!/g, '%21');
  toSign = toSign.replace(/'/g, '%27');
  toSign = toSign.replace(/\*/g, '%2A');
  toSign = toSign.replace(/\(/g, '%28');
  toSign = toSign.replace(/\)/g, '%29');

  query.Signature = crypto.createHmac(
      'sha256',
      options.key
  ).update(toSign).digest('base64');

  if (req.qs) {
    req.qs.Action = query.Action;
  }
  else {
    req.qs = {
      Action: query.Action
    };
  }

  delete query.Action;

  req.body = Object.keys(query).sort().map(function (key) {
    return encodeURIComponent(key) + '=' + encodeURIComponent(query[key]);
  }).join('&');

  req.headers['Content-Type'] = 'application/x-www-form-urlencoded';
  req.headers['Content-Length'] = Buffer.byteLength(req.body);
};

exports.signHeaders = function signHeaders(req, options) {
  if (!options) options = {};

  if (typeof options.key !== 'string') {
    throw new TypeError('`key` is a required argument for aws-signature');
  }

  if (typeof options.keyId !== 'string') {
    throw new TypeError('`keyId` is a required argument for aws-signature');
  }

  req.headers = req.headers || {};

  // Lower-case keys in headers hashmap
  var headers = {};
  Object.keys(req.headers).forEach(function (key) {
    headers[key.toLowerCase()] = req.headers[key];
  });

  var now = new Date(),
      signatureString = [
        req.method || 'GET', '\n',
        headers['content-md5'] || '', '\n',
        headers['content-type'] || '', '\n',
        now.toUTCString(), '\n'
      ];

  // Push amz headers to signature string
  Object.keys(headers).forEach(function (key) {
    if (/^x-amz/.test(key)) {
      signatureString.push(key, ':', headers[key], '\n');
    }
  });

  if (req.signingUrl) {
    signatureString.push(req.signingUrl);
  }
  else {
    signatureString.push(req.path);
  }

  var signature = crypto.createHmac(
      'sha1',
      options.key
  ).update(signatureString.join('')).digest('base64');

  req.headers.Date = now.toUTCString();
  req.headers.Authorization = 'AWS ' + options.keyId + ':' + signature;
};
