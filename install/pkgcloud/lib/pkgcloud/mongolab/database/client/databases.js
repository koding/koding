/*
 * database.js: Database methods for working with databases from MongoLab
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var pkgcloud = require('../../../../../lib/pkgcloud'),
    errs     = require('errs'),
    qs       = require('querystring'),
    url      = require('url');


// Function formatResponse
// This function parse the response from the provider and return an object
// with the correct keys and values.
// ### @response {Object} The body response from the provider api
function formatResponse(response) {
  var info, user, dbname, auth;
  info   = url.parse(response.uri);
  auth   = encodeURIComponent(info.auth);
  user   = auth.replace(/%3A/i, ':').split(':');
  dbname = response.name;

  var database = {
    id: dbname,
    host: info.hostname,
    port: Number(info.port),
    uri: 'mongodb://' + info.auth + '@' + info.host,
    username: decodeURIComponent(user[0]),
    password: decodeURIComponent(user[1]),
    dbname: dbname
  };
  return database;
}

// Create Database
// ### @options {Object} Set of options can be
// #### options['name'] {String} Name of database (required)
// #### options['owner'] {String} Name of the user owner the database (required)
// #### options['plan'] {String} Name of plan according to the MongoLab plans (Default: 'free')
// ### @callback {Function} Continuation to respond to when complete.
exports.create = function create(options, callback) {
  // Check for options
  if (typeof options === 'function') {
    return errs.handle(errs.create({
      message: 'Options required for create a database.'
    }), options);
  }

  if (!options['name']) {
    return errs.handle(errs.create({
      message: 'options. Name is a required argument'
    }), callback);
  }

  if (!options['owner']) {
    return errs.handle(errs.create({
      message: 'options. Owner is a required argument'
    }), callback);
  }

  if (!options['plan']) {
    options['plan'] = 'free';
  }

  // We have to setup the correct prefix for database name
  // for the moment we use the 'owner' field because we expect the correct prefix there.
  var databaseName = [options['owner'], options['name']].join('_');

  // Setup the account name according mongolab API.
  // @todo We need a helper function for add the prefix if its necesary
  //var account = [this.config.username, options['owner']].join('_');
  // at the moment we need provide the username with the prefix (partner name)
  var account = options['owner'];

  var createOptions = {
    method: 'POST',
    path: 'accounts/' + account + '/databases',
    body: {
      name: databaseName,
      plan: options['plan'],
      username: options['owner'],
      // In future we will have to change this for support multiples clouds and user-selected cloud.
      cloud: this.config.cloud
    }
  };

  this._request(createOptions, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, formatResponse(body));
  });
};

// Lists all databases by user account
// ### @owner {String} Username for list their databases
// ### @callback {Function} Continuation to respond to when complete.
exports.getDatabases = function getDatabases(owner, callback) {
  // Check for options
  if (typeof owner === 'function') {
    return errs.handle(errs.create({
      message: 'Name required for delete an account.'
    }), owner);
  }

  this._request({ path: 'accounts/' + owner + '/databases' }, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, body);
  });
};

// View one database with details
// NOT USE THIS METHOD YET
// The principal idea of this method is for view details like username and
// password and the hostname and port, but for now MongoLab just answer with the name.
// The behavior I describe its according the parters documentation.
// https://objectlabs.jira.com/wiki/display/partners/MongoLab+Partner+Integration+API#MongoLabPartnerIntegrationAPI-Viewdatabase
// ### @options {Object} Set of options can be
// #### options['name'] {String} Name of the database to view (required)
// #### options['owner'] {String} Username of the database owner (required)
// ### @callback {Function} Continuation to respond to when complete.
exports.getDatabase = function getDatabase(options, callback) {
  // Check for options
  if (typeof options === 'function') {
    return errs.handle(errs.create({
      message: 'Options required for view a database.'
    }), options);
  }

  // Check for name
  if (!options['name']) {
    return errs.handle(errs.create({
      message: 'options. Name is a required argument.'
    }), callback);
  }

  // Check for owner
  if (!options['owner']) {
    return errs.handle(errs.create({
      message: 'options. Username of owner is a required argument.'
    }), callback);
  }

  var path = ['accounts', options['owner'], 'databases', options['name']].join('/');

  this._request({ path: path }, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, body);
  });
};

// Delete a database
// ### @options {Object} Set of options can be
// #### options['name'] {String} Name of the database to view (required)
// #### options['owner'] {String} Username of the database owner (required)
// ### @callback {Function} Continuation to respond to when complete.
exports.remove = function remove(options, callback) {
  // Check for options
  if (typeof options === 'function') {
    return errs.handle(errs.create({
      message: 'Options required for delete a database.'
    }), options);
  }

  // Check for name
  if (!options['name']) {
    return errs.handle(errs.create({
      message: 'options. Name is a required argument.'
    }), callback);
  }

  // Check for owner
  if (!options['owner']) {
    return errs.handle(errs.create({
      message: 'options. Username of owner is a required argument.'
    }), callback);
  }

  var deleteOptions = {
    method: 'DELETE',
    path: ['accounts', options['owner'], 'databases', options['name']].join('/')
  };

  this._request(deleteOptions, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null);
  });
};
