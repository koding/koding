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
// ####     @clientKey {String} Client key
// ####     @apiKey    {String} API key
// #### @throws {TypeError} On bad input
//
var Client = exports.Client = function (opts) {
  if (!opts || !opts.clientId || !opts.apiKey) {
    throw new TypeError('clientId and apiKey are required');
  }

  base.Client.call(this, opts);

  this.provider = 'digitalocean';
  this.protocol = opts.protocol || 'https://';
  this.serversUrl = opts.serversUrl;
  
  if (!this.before) {
    this.before = [];
  }

  this.before.push(function setJSON(req) {
    req.json = true;
    if (typeof req.body !== 'undefined') {
      req.json = req.body;
      delete req.body;
    }
  });

  this.before.push(function setAuth(req) {
    req.qs = req.qs || {};

    req.qs.client_id = opts.clientId;
    req.qs.api_key = opts.apiKey;
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
