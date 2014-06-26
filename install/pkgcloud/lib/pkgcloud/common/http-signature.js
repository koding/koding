/*
 * http-signature.js: Implmentation of `http-signature` authentication.
 *
 * Copyright (C) 2011 Joyent, Inc.  All rights reserved.
 * MIT License
 *
 * Modified by Nodejitsu, under MIT
 *
 */

var assert = require('assert'),
    crypto = require('crypto'),
    http = require('http');

//
// ## Globals
//
var Algorithms = {
  'rsa-sha1': true,
  'rsa-sha256': true,
  'rsa-sha512': true,
  'dsa-sha1': true,
  'hmac-sha1': true,
  'hmac-sha256': true,
  'hmac-sha512': true
};

var Authorization = 'Signature keyId="%s",algorithm="%s",headers="%s" %s';

//
// ## Specific Errors
//
function MissingHeaderError(message) {
  this.name = 'MissingHeaderError';
  this.message = message;
  this.stack = (new Error()).stack;
}

MissingHeaderError.prototype = new Error();

function InvalidAlgorithmError(message) {
  this.name = 'InvalidAlgorithmError';
  this.message = message;
  this.stack = (new Error()).stack;
}

InvalidAlgorithmError.prototype = new Error();

//
// ## Internal Functions
//
function _pad(val) {
  return parseInt(val, 10) < 10
    ? val = '0' + val
    : val;
}

function _rfc1123() {
  var date = new Date(),
      months,
      days;

  days   = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  months = [
    'Jan', 'Feb', 'Mar',
    'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep',
    'Oct', 'Nov', 'Dec'
  ];

  return days[date.getUTCDay()] + ', ' +
    _pad(date.getUTCDate())     + ' '  +
    months[date.getUTCMonth()]  + ' '  +
    date.getUTCFullYear()       + ' '  +
    _pad(date.getUTCHours())    + ':'  +
    _pad(date.getUTCMinutes())  + ':'  +
    _pad(date.getUTCSeconds())  + ' GMT';
}

//
// ## Exported API methods
//
module.exports = {
  sign: function (req, options) {
    if (!options || !(options instanceof Object)) {
      throw new TypeError('options must be an Object');
    }

    if (!options.keyId || typeof options.keyId !== 'string') {
      throw new TypeError('options.keyId must be a String');
    }

    if (options.algorithm && typeof options.algorithm !== 'string') {
      throw new TypeError('options.algorithm must be a String');
    }

    if (!options.algorithm) {
      options.algorithm = 'rsa-sha256';
    }

    options.algorithm = options.algorithm.toLowerCase();
    if (!Algorithms[options.algorithm]) {
      throw new InvalidAlgorithmError(options.algorithm + ' is not supported');
    }

    var stringToSign = _rfc1123(),
        alg = options.algorithm.match(/(hmac|rsa)-(\w+)/),
        signature,
        signer,
        hmac;

    if (alg[1] === 'hmac') {
      hmac = crypto.createHmac(alg[2].toUpperCase(), options.key);
      hmac.update(stringToSign);
      signature = hmac.digest('base64');
    } else {
      signer = crypto.createSign(options.algorithm.toUpperCase());
      signer.update(stringToSign);
      signature = signer.sign(options.key, 'base64');
    }

    req.headers = req.headers || {};
    req.headers.date = stringToSign;
    req.headers.Authorization =
      'Signature keyId="' + options.keyId + '",algorithm="' +
      options.algorithm + '",headers="date" ' + signature;

    return req;
  }
};