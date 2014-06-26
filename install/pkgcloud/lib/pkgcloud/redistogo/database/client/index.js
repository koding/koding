/*
 * client.js: Database client for RedisToGo Cloud Databases
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var utile     = require('utile'),
    request   = require('request'),
    pkgcloud  = require('../../../../pkgcloud'),
    errs      = require('errs');

var Client = exports.Client = function (options) {
  this.username = options.username;
  this.password = options.password;
  this._url = options.url || "https://redistogo.com";
};

Client.prototype._getUrl = function () {
  return this._url;
};

//
// Wrapper for all http requests with RedisToGo
//

Client.prototype._request = function (options, callback) {
  var self = this;

  options.headers['User-Agent'] = utile.format('nodejs-pkgcloud/%s', pkgcloud.version);

  request(options, function (err, response, body) {
    if (err) {
      return callback(err);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return callback("Unauthorized");
    }
    if (options.method !== "DELETE") {
      var database;
      if (typeof body !== 'object') {
        try {
          database = JSON.parse(body);
        } catch (e) {
          return callback("Bad response from server.", body);
        }
      } else { database = body; }
      database = self.formatResponse(database);
      return callback(null, database);
    } else {
      return callback(null, 'deleted');
    }
  });
};

//  Create a new database at redistogo
//  Need a correct plan
//  ### @attrs {Object} Map of options
//  ##### @attrs['plan'] Plan for the database.(required)
Client.prototype.create = function (attrs, callback) {
  // Check for options.
  if (!attrs || typeof attrs === 'function') {
    return errs.handle(errs.create({
      message: 'Options required for create a database.'
    }), Array.prototype.slice.call(arguments).pop());
  }
  // Check for plan.
  if (!attrs['plan']) {
    attrs['plan'] = 'nano';
  }
  //
  // TODO: Add validation for options.plan types
  //
  var options = {
    uri    : this._getUrl() + '/instances.json',
    method : 'POST',
    body   : 'instance%5Bplan%5D=' + attrs.plan,
    headers: {
      'Authorization': "Basic " + utile.base64.encode(this.username + ':' + this.password)
    }
  };
  this._request(options, callback);
};

//  Get information about specific database
//  Need the database ID
//  ### @id {String} ID of the database.(required)
Client.prototype.get = function (id, callback) {
  // Check for id
  if (!id || typeof id === 'function') {
    return errs.handle(errs.create({
      message: 'ID is a required argument'
    }), Array.prototype.slice.call(arguments).pop());
  }
  var options,
      path = '/instances',
      self = this;
  if (id !== null) {
    path = path + '/' + id;
  }
  options = {
    uri    : this._getUrl() + path + '.json',
    method : 'GET',
    headers: {
      'Authorization': "Basic " + utile.base64.encode(this.username + ':' + this.password)
    }
  };
  this._request(options, callback);
};

//  Removes one Redis instance by id
//  Need the database ID
//  ### @id {String} ID of the database.(required)
Client.prototype.remove = function (id, callback) {
  // Check for id
  if (!id || typeof id === 'function') {
    return errs.handle(errs.create({
      message: 'ID is a required argument'
    }), Array.prototype.slice.call(arguments).pop());
  }
  var options,
      path = '/instances/' + id,
      self = this;
  options = {
    uri    : this._getUrl() + path + '.json',
    method : 'DELETE',
    headers: {
      'Authorization': "Basic " + utile.base64.encode(this.username + ':' + this.password),
      'Content-Length': 0
    }
  };
  this._request(options, callback);
};

Client.prototype.formatResponse = function (response) {
  var database = {
    id: response.id,
    port: response.port,
    host: response.label.split('-')[0] + '.redistogo.com',
    uri: 'redis://nodejitsu:' +  response.password + '@' + response.label.split('-')[0] + '.redistogo.com:' + response.port,
    username: 'nodejitsu',
    password: response.password,
    metadata: response
  };
  return database;
};