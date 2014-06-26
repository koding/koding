/*
 * database.js: Database methods for working with databases from MongoHQ
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

 var errs     = require('errs'),
     url      = require('url');

// Function formatResponse
// This function parse the response from the provider and return an object
// with the correct keys and values.
// ### @response {Object} The body response from the provider api
function formatResponse(response) {
  var info, user, dbname, database, auth;
  info   = url.parse(response.config.MONGOHQ_URL);
  auth   = encodeURIComponent(info.auth);
  user   = auth.replace(/%3A/i, ':').split(':');
  dbname = info.pathname.replace('/', ''),
  database = {
    id: response.id,
    port: Number(info.port),
    host: info.hostname,
    uri: 'mongodb://' + info.auth + '@' + info.host,
    username: decodeURIComponent(user[0]),
    password: decodeURIComponent(user[1]),
    dbname: dbname
  };
  return database;
}

//  Create a new Database at mongohq
//  Need Name and select a plan.
//  ### @options {Object} pair of name an plan values.
//  ##### @options['name'] {String} Name of the new database.(required)
//  ##### @options['plan'] {String} Name of the plan selected for database.(required)
exports.create = function create(options, callback) {
  // Check for options
  if (!options || typeof options === 'function') {
    return errs.handle(errs.create({
      message: 'Options required for create a database.'
    }), Array.prototype.slice.call(arguments).pop());
  }
  // Check for name
  if (!options['name']) {
    return errs.handle(errs.create({
      message: 'options. Name are required arguments'
    }), Array.prototype.slice.call(arguments).pop());
  }

  // Check for plan
  if (!options['plan']) {
    options['plan'] = 'free';
  }

  var createOptions = {
    path    : 'resources',
    method  : 'POST',
    body    : 'app_id=' + options.name + '&plan=' + options.plan
  };

  this._request(createOptions, function (err, b, response) {
    if (err) {
      return callback(err);
    }
    var body;
    if (typeof b !== 'object') {
      try {
        body = JSON.parse(b);
      } catch (e) {
        return errs.handle(errs.create({
          messages: 'Bad response from server.'
        }), callback);
      }
    } else { body = b; }
    return callback(null, formatResponse(body));
  });
};

//
//  Removes one mongo instance by id
//  ### @id {String} ID of the instance to remove.
exports.remove = function remove(id, callback) {
  // Check for id
  if (!id || typeof id === 'function') {
    return errs.handle(errs.create({
      message: 'ID is a required argument'
    }), Array.prototype.slice.call(arguments).pop());
  }

  var deleteOptions = {
    path   : 'resources/' + id,
    method : 'DELETE'
  };

  this._request(deleteOptions, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, 'deleted');
  });
};