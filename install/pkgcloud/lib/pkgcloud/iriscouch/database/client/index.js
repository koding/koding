/*
 * client.js: Database client for Iriscouch Cloud Databases
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

  this.protocol = options.protocol || 'https://';
  this.databaseUrl = options.databaseUrl || 'hosting.iriscouch.com/hosting_public';
};

Client.prototype.create = function (attrs, callback) {
  // Check for options.
  if (!attrs || typeof attrs === 'function') {
    return errs.handle(errs.create({
      message: 'Options required for create a database.'
    }), Array.prototype.slice.call(arguments).pop());
  }
  // Check for obligatory fields
  if (!attrs['first_name'] || !attrs['last_name']) {
    return errs.handle(errs.create({
      message: 'Options.  first_name and last_name are required arguments'
    }), Array.prototype.slice.call(arguments).pop());
  }

  if (!attrs['subdomain'] || !attrs['email']) {
    return errs.handle(errs.create({
      message: 'Options.  subdomain and email are required arguments'
    }), Array.prototype.slice.call(arguments).pop());
  }

  // If is a redis provisioning request so we have to define a password
  if (attrs['type'] && attrs['type'] === 'redis' && !attrs['password']) {
    return errs.handle(errs.create({
      message: 'Options.  password for redis is a required argument'
    }), Array.prototype.slice.call(arguments).pop());
  }

  var self = this,
    couch = {
      // The ID needs the prefix of the type of database
      _id: ((attrs['type'] &&
        attrs['type'] === 'redis') ? "Redis/" : "Server/") + attrs.subdomain,
      partner:  this.username,
      creation: {
        "first_name": attrs.first_name,
        "last_name": attrs.last_name,
        "email": attrs.email,
        "subdomain": attrs.subdomain
      }
  };

  // When redis so we have to add the password
  if (attrs['type'] && attrs['type'] === 'redis') {
    couch.creation.password = attrs['password'];
  }

  var options = {
    uri    : this._getUrl(),
    method : 'POST',
    body   : JSON.stringify(couch),
    followRedirect: false,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': "Basic " + utile.base64.encode(this.username + ':' + this.password),
      'User-Agent': utile.format('nodejs-pkgcloud/%s', pkgcloud.version)
    }
  };

  request(options, function (err, response, body) {
    if (err) {
      return callback(err);
    }

    if (typeof body === 'string') {
      try { body = JSON.parse(body) }
      catch (ex) { }
    }

    if (response.statusCode === 201) {
      if (body.ok === true) {
        //
        // For Redis we dont have any polling method yet, so just trust on iriscouch for provisioning correctly
        //
        if (attrs['type'] && attrs['type'] === 'redis') {
          var subdomain = body.id.split('/').pop();
          callback(err, {
            id: subdomain,
            port: 6379,
            host: subdomain + '.redis.irstack.com',
            uri: 'redis://' + subdomain + '.redis.irstack.com/',
            username: '',
            password: subdomain + '.redis.irstack.com:' + attrs['password']
          });
        } else {
          //
          // Remark: Begin polling iriscouch to determine when the couch database is ready.
          //
          self._checkCouch(attrs.subdomain, function (err, response) {
            response.subdomain = attrs.subdomain;
            var database = self.formatResponse(response);
            callback(err, database);
          });
        }
      }
      else {
        callback("There was an issue creating the couch", { "created": false });
      }
    }
    else if (response.statusCode === 403 || response.statusCode === 401 || response.statusCode === 302) {
      callback("incorrect partner name or password.", { "created": false });
    }
    else if (response.statusCode === 409) {
      callback("subdomain is already taken.", { "created": false });
    }
    else {
      callback("unknown error", { "created": false });
    }
  });
};

Client.prototype.formatResponse = function (response) {
  var database = {
    id: response.subdomain,
    port: 6984,
    host: response.subdomain + '.iriscouch.com',
    uri: 'https://' + response.subdomain + '.iriscouch.com:6984/',
    username: '',
    password: ''
  };
  return database;
};

Client.prototype._getUrl = function () {
  return this.protocol + this.databaseUrl;
};

Client.prototype._checkCouch = function (couchName, callback) {
  //
  // Remark: Poll the couch with a GET every interval to determine if couch is up yet
  // We perform a poll since there is no real database available notification event from couchone
  //

  var interval = 4000,
      maxAttempts = 20,
      count = 0,
      options = {
        uri    : this._getCouchPollingUrl(couchName),
        method : 'GET',
        followRedirect: false,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': utile.format('nodejs-pkgcloud/%s', pkgcloud.version)
        }
      },

  t = function () {
    count = count + 1;
    if (count > maxAttempts) {
      return callback("Max Attempts hit", { "created": false });
    }
    request(options, function (err, response, body) {
      if (err) {
        return callback(err, { "created": false });
      }
      if (response.statusCode === 200) {
        return callback(null, { "created": true });
      }
      setTimeout(t, interval);
    });
  };
  t();
};

Client.prototype.remove = function (id, callback) {
  callback("Destroy method not available for iriscouch.");
};

// This function gets overriden in tests to trap the polling request
Client.prototype._getCouchPollingUrl = function(couchName) {
  return 'http://' + couchName + '.iriscouch.com/';
};
