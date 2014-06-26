/*
 * database.js: Database methods for working with database within instances from Rackspace Cloud
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var pkgcloud = require('../../../../../lib/pkgcloud'),
    Database = pkgcloud.providers.rackspace.database.Database,
    Instance = pkgcloud.providers.rackspace.database.Instance,
    errs     = require('errs'),
    qs       = require('querystring');

// Create Database within a Instance
// Need a Instance
// ### @options {Object} Set of options can be
// #### options['name'] {string} Name of database (required)
// #### options['instance'] {string | Object} The instance could be the ID or a instance of Instance class (required)
// #### options['character_set'] {string} Should be a valid CharacterSet for mysql. Default to 'utf8'
// #### options['collate'] {string} Should be a valid Collate for mysql. Default to 'utf8_general_ci'
// For more info about character_set and collate for mysql see http://dev.mysql.com/doc/refman/5.6/en/charset-mysql.html
exports.createDatabase = exports.create = function createDatabase(options, callback) {
  var self = this;

  // Check for options
  if (!options || typeof options === 'function') {
    return errs.handle(errs.create({
      message: 'Options required for create a database.'
    }), options);
  }

  if (!options['name']) {
    return errs.handle(errs.create({
      message: 'options. Name is a required argument'
    }), callback);
  }

  if (!options['instance']) {
    return errs.handle(errs.create({
      message: 'options. Instance is a required argument'
    }), callback);
  }

  // @todo Add support for handle and array of names for create multiple databases

  var instanceId = options['instance'] instanceof Instance ? options['instance'].id : options['instance'];

  // We setup a template for the database to create
  var reqDatabase = { name: options['name'] };

  // If is specified we set this options.
  if (options && options['character_set']) {
    reqDatabase['character_set'] = options['character_set'];
  }

  if (options && options['collate']) {
    reqDatabase['collate'] = options['collate'];
  }

  var createOptions = {
    method: 'POST',
    path: 'instances/' + instanceId + '/databases',
    body: {
      databases: [reqDatabase]
    }
  };

  this._request(createOptions, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, response);
  });
};

// List of databases from an instance.
// ### @options {Object} Set of options can be
// #### options['instance'] {string | Object} The instance could be the ID or a instance of Instance class (required)
// #### options['limit'] {Integer} Number of results you want
// #### options['offset'] {Integer} Offset mark for result list
// ### @callback {Function} Function to continue the call is cb(error, instances, offset)
exports.getDatabases = function getDatabases(options, callback) {
  var self = this,
      completeUrl = {},
      requestOptions = {};

  if (typeof options === 'function') {
    return errs.handle(errs.create({
      message: 'An instance is required for get all databases.'
    }), Array.prototype.slice.call(arguments).pop());
  }
  // Check for instance
  if (!options['instance']) {
    return errs.handle(errs.create({
      message: 'An instance is required for get all databases.'
    }), Array.prototype.slice.call(arguments).pop());
  }
  // The limit parameter for truncate results
  if (options && options.limit) {
    completeUrl.limit = options.limit;
  }
  // The offset
  if (options && options.offset) {
    completeUrl.marker = options.offset;
  }

  var instanceId = options['instance'] instanceof Instance ? options['instance'].id : options['instance'];

  requestOptions.qs = completeUrl;
  requestOptions.path = 'instances/' + instanceId + '/databases';

  this._request(requestOptions, function (err, body, response) {
    if (err) {
      return callback(err);
    }

    var marker = null;
    if (body.links && body.links.length > 0) {
      marker = qs.parse(body.links[0].href.split('?').pop()).marker;
    }

    return callback(null, body.databases.map(function (result) {
      return new Database(self, result);
    }), marker);
  });
};

// Deleting a database within an instance
// #### @database {string | Object} The database could be the ID or a instance of Database class (required)
// #### @instance {string | Object} The instance could be the ID or a instance of Instance class (required)
exports.destroyDatabase = function destroyDatabases(database, instance, callback) {
  // Check for database
  if (typeof database === 'function') {
    return errs.handle(errs.create({
      message: 'A database is a required.'
    }), database);
  }

  // Check for instance
  if (typeof instance === 'function') {
    return errs.handle(errs.create({
      message: 'An instance is a required for destroy databases.'
    }), instance);
  }

  var instanceId = instance instanceof Instance ? instance.id : instance;
  var databaseName = database instanceof Database ? database.name : database;

  this._request({
    method: 'DELETE',
    path: 'instances/' + instanceId + '/databases/' + databaseName
  }, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, response);
  });
};
