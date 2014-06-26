/*
 * client.js: Base client from which all Joyent clients inherit from
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    fs    = require('fs'),
    auth  = require('../common/auth'),
    base  = require('../core/base');

//
// ### constructor (options)
// #### @opts {Object} an object literal with options
// ####     @serversUrl {String} **Optional** CloudAPI Endpoint
// ####     @apiVersion {String} **Optional** CloudAPI API Version
// ####     @account    {String} **Optional** CloudAPI Account to connect to
// ####     @username   {String} **Optional** Login name
// ####     @password   {String} **Optional** Password that goes with username
// ####     @keyId      {String} **Optional** SSH KeyId to sign in to cloudapi
// ####     @key        {String} **Optional** SSH key (PEM) that goes
// ####     @identity   {String} **Optional** File path of the private key
// with `keyId`.
// #### @throws {TypeError} On bad input
//
// Creates a new Joyent CloudAPI Client. Even though all @opts are optional
// you must either provide username/password or keyId/key
//
var Client = exports.Client = function (opts) {
  if (!opts) {
    throw new TypeError('options required');
  }

  if (opts.identity) {
    opts.key = fs.readFileSync(opts.identity, 'ascii');
  }

  if (!(opts.username && opts.password) &&
      !(opts.keyId && opts.key)) {
    throw new TypeError('Either username/password or keyId/key are required');
  }

  // default values
  opts.account    = opts.account    || opts.username || 'my';
  opts.apiVersion = opts.apiVersion || '~6.5';

  // if a person gives a key id by name that doesn't work in joyent
  // keys are fully qualified. so we check for `/` in the keyId, if it's not
  // there we need to do something about it
  if (opts.keyId && opts.keyId.indexOf('/') === -1) {
    // this will fail if account was also not properly set and account is
    // set to `my`.
    opts.keyId = '/' + opts.account + '/keys/' + opts.keyId;
  }

  base.Client.call(this, opts);

  this.provider   = 'joyent';
  this.account    = opts.account;
  this.serversUrl = opts.serversUrl
    || process.env.SDC_CLI_URL
    || 'us-sw-1.api.joyentcloud.com';
  this.protocol   = opts.protocol || 'https://';

  if (!this.before) { this.before = []; }

  if (opts.key && opts.keyId) {
    this.before.push(auth.httpSignature);
  } else {
    this.before.push(auth.basic);
  }

  this.before.push(function setReqHeaders(req) {
    req.json = true;
    if (typeof req.headers["X-Api-Version"] === 'undefined') {
      req.headers["x-api-version"] = opts.apiVersion;
      req.headers.Accept = 'application/json';
      req.headers['content-type'] = 'application/json';
    }
  });

  this.before.push(function setContentTypeAndReqJson(req) {
    if (typeof req.body !== 'undefined') {
      req.json = req.body;
      delete req.body;
    }
  });
};

utile.inherits(Client, base.Client);

Client.prototype.failCodes = {
  400: 'Bad Request',
  401: 'Unauthorized',
  403: 'Forbidden',
  404: 'Not Found',
  405: 'Method Not Allowed',
  406: 'Not Acceptable',
  409: 'Conflict',
  413: 'Request Entity Too Large',
  415: 'Unsupported Media Type',
  420: 'Slow Down',
  449: 'Retry With',
  500: 'Internal Error',
  503: 'Service Unavailable'
};

Client.prototype.successCodes = {
  200: 'OK',
  201: 'Created',
  202: 'Accepted',
  203: 'Non-authoritative information',
  204: 'No content'
};
