/*
 * database.js: Database methods for working with databases from Azure Tables
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var errs = require('errs'),
  async = require('async'),
  templates = require('../../utils/templates'),
  PATH = require('path'),
  xml2js = require('xml2js'),
  _ = require('underscore'),
  url = require('url');

//  Create a new Azure Table Database
//  Need name of table to create
//  ### @options {Object} table create options.
//  ##### @options['name'] {String} Name of the new table.(required)
exports.create = function (options, callback) {

  var params = {},
    headers = {},
    self = this,
    body;

  if (!options || typeof options === 'function') {
    return errs.handle(errs.create({
      message: 'Options required to create a database.'
    }), Array.prototype.slice.call(arguments).pop());
  }

  // Check for name
  if (!options['name']) {
    return errs.handle(errs.create({
      message: 'options. name is a required option'
    }), Array.prototype.slice.call(arguments).pop());
  }

  params.name = options.name;
  params.date = new Date().toISOString();

  // async execute the following tasks one by one and bail if there is an error
  async.waterfall([
    function (next) {
      var path = PATH.join(__dirname, 'templates/createTable.xml');
      templates.load(path, next);
    },
    function (template, next) {
      // compile template with params
      body = _.template(template, params);
      headers['content-length'] = body.length;
      self._request({
        method: 'POST',
        path: 'Tables',
        body: body,
        headers: headers
      }, function (err, body, res) {
        if (err) { return next(err); }

        var parser = new xml2js.Parser();
        parser.parseString(body || '', function (err, data) {
          return !err
            ? next(null, data)
            : next(err);
        });
      });
    }],
    function (err, result) {
      return !err
        ? callback(null, self.formatResponse(result))
        : callback(err);
    }
  );
};

//  List the Azure Tables in the current account
// ### @callback {Function} Continuation to respond to when complete. Returns array of Database objects.
exports.list = function (callback) {
  var tables = [],
      self = this;

  this._xmlRequest({
    method: 'GET',
    path: 'Tables'
  }, function (err, body, res) {
    if (err) { return callback(err); }
    if (body && body.entry) {
      if (Array.isArray(body.entry)) {
        body.entry.forEach(function (table) {
          tables.push(self.formatResponse(table));
        });
      } else {
        tables.push(self.formatResponse(body.entry));
      }
    }
    callback(null, tables);
  });
};

// Delete a database
// ### @options {Object} Set of options can be
// #### options['id'] {String} id of the database to delete (required)
// ### @callback {Function} Continuation to respond to when complete.
exports.remove = function (id, callback) {
  var path;
  if (!id || typeof id === 'function') {
    return errs.handle(errs.create({
      message: 'id is a required argument'
    }), Array.prototype.slice.call(arguments).pop());
  }

  path = encodeTableUriComponent("Tables('" + id + "')");
  this._xmlRequest({
    method: 'DELETE',
    path: path
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, res.statusCode === 204);
  });
};

// Encode a uri according to Azure Table rules
// ### @options {uri} The uri to encode
// ### @return {String} The encoded uri.
var encodeTableUriComponent = function (uri) {
  return encodeURIComponent(uri)
    .replace(/!/g, '%21')
    .replace(/'/g, '%27')
    .replace(/\(/g, '%28')
    .replace(/\)/g, '%29')
    .replace(/\*/g, '%2A');
};
