/*
 * instances.js: Instance methods for working with database instances from Rackspace Cloud
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var pkgcloud = require('../../../../../lib/pkgcloud'),
    Flavor   = pkgcloud.providers.rackspace.database.Flavor,
    Instance = pkgcloud.providers.rackspace.database.Instance,
    errs     = require('errs'),
    qs       = require('querystring');

// Create Database Instance
// Need a flavor
// ### @options {Object} Set of options can be
// #### options['name'] {string} Name of instance (required)
// #### options['flavor'] {string | Object} Should be the HREF for the flavor or a instance of Flavor class (required)
// #### options['size'] {number} The Volume size in Gigabytes, must be between 1 and 8
// #### options['databases'] {array} Array of strings with database names to create when the instance is ready.
// ### @callback {Function} Function to continue the call is cb(error, Instance)
exports.createInstance = function createInstance(options, callback) {
  var self = this,
      flavorRef,
      size;

  // Check for options
  if (!options || typeof options === 'function') {
    return errs.handle(errs.create({
      message: 'Options required for create an instance.'
    }), options);
  }

  if (!options['name']) {
    return errs.handle(errs.create({
      message: 'options. name is a required argument'
    }), callback);
  }

  if (!options['flavor']) {
    return errs.handle(errs.create({
      message: 'options. flavor is a required argument'
    }), callback);
  }

  // If the 'databases' are specified we create a template for each database name.
  if (options && options['databases'] &&
      typeof options['databases'] === 'array' &&
      options['databases'].length > 0) {
    options['databases'].forEach(function (item, idx) {
      if (typeof item === 'string') {
        // This template is according to the defaults of rackspace.
        options['databases'][idx] = {
          name: item,
          character_set: "utf8",
          collate: 'utf8_general_ci'
        };
      }
    });
  }

  // Check for the correct value of 'size', should be between 1 and 8 otherwise will be 1
  if (options && options['size']) {
    // Ensure size is an Integer
    if (typeof options['size'] !== 'number') {
      return errs.handle(errs.create({
        message: 'options. Volume size should be a Number, not a String'
      }), callback);
    }
    size = (options['size'] > 0 && options['size'] < 9) ? options['size'] : 1;
  }

  // Extract the href value of the Flavor instance
  // Should be always true because above we return an error if not exists
  if (options && options['flavor']) {
    flavorRef = options['flavor'] instanceof Flavor ? options['flavor'].href : options['flavor'];
  }

  var createOptions = {
    method: 'POST',
    path: 'instances',
    body: {
      instance: {
        name: options['name'],
        flavorRef: flavorRef,
        databases: options['databases'] || [],
        volume: { size: size || 1 }
      }
    }
  };

  this._request(createOptions, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, new Instance(self, body.instance));
  });
};

// Gets all instances info
// ### @options {Object} Set of options can be
// #### options['limit'] {Integer} Number of results you want
// #### options['offset'] {Integer} Offset mark for result list
// ### @callback {Function} Function to continue the call is cb(error, instances, offset)
exports.getInstances = function getInstances(options, callback) {
  var self = this,
      completeUrl = {},
      requestOptions = {};

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  // The limit parameter for truncate results
  if (options && options.limit) {
    completeUrl.limit = options.limit;
  }

  // The offset
  if (options && options.offset) {
    completeUrl.marker = options.offset;
  }

  requestOptions.qs = completeUrl;
  requestOptions.path = 'instances';

  this._request(requestOptions, function (err, body, res) {
    if (err) {
      return callback(err);
    }

    var marker = null;
    if (body.links && body.links.length > 0) {
      marker = qs.parse(body.links[0].href.split('?').pop()).marker;
    }

    callback(null, body.instances.map(function (result) {
      return new Instance(self, result);
    }), marker);
  });
};

// Destroying the database instance
// ### @instance {string | Object} The ID of the istance of a instance of Instance class (required)
// ### @callback {Function} Function to continue the call is cb(error, res)
exports.destroyInstance = function destroyInstance(instance, callback) {
  // Check for instance
  if (typeof instance === 'function') {
    return errs.handle(errs.create({
      message: 'An instance is required.'
    }), instance);
  }

  var instanceId = instance instanceof Instance ? instance.id : instance;
  this._request({
    method: 'DELETE',
    path: 'instances/' + instanceId
  }, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, response);
  });
};

// Details of specific instance
// ### @instance {string | Object} The ID of the istance of a instance of Instance class (required)
// ### @callback {Function} Function to continue the call is cb(error, instances, offset)
exports.getInstance = function getInstance(instance, callback) {
  // Check for instance
  if (typeof instance === 'function') {
    return errs.handle(errs.create({
      message: 'An instance is required.'
    }), instance);
  }

  var self = this;
  var instanceId = instance instanceof Instance ? instance.id : instance;
  this._request({
    path: 'instances/' + instanceId
  }, function (err, body, response) {
    return err
      ? callback(err)
      : callback(null, new Instance(self, body.instance));
  });
};

// Restart the Instance
// Call this function cause a restart in the instance specified
// ### @instance {string | Object} The ID of the istance of a instance of Instance class (required)
// ### @callback {Function} Function to continue the call is cb(error)
exports.restartInstance = function restartInstance(instance, callback) {
  // Check for instance
  if (typeof instance === 'function' || typeof instance === 'undefined') {
    return errs.handle(errs.create({
      message: 'An instance is required.'
    }), Array.prototype.slice.call(arguments).pop());
  }

  var instanceId = instance instanceof Instance ? instance.id : instance;

  var restartOptions = {
    method: 'POST',
    path: 'instances/' + instanceId + '/action',
    body: { restart: {} }
  };

  this._request(restartOptions, function (err, body, response) {
    if (err) {
      return callback(err);
    }

    if (response.statusCode === 202) {
      return callback(null);
    }

    errs.handle(errs.create({
      message: 'Bad response from restart action.'
    }), callback);
  });
};

// Resize the memory of the database instance.
// You can use this to change the flavor of the database instance, need a new flavor.
// ### @instance {string | Object} The ID of the istance of a instance of Instance class (required)
// ### @flavor {Flavor class} The flavor to resize the instance, should be different (required)
// ### @callback {Function} Function to continue, no params are passed.
exports.setFlavor = function setFlavor(instance, flavor, callback) {
  // Check for the flavor
  if (typeof flavor === 'function' || typeof flavor === 'undefined') {
    return errs.handle(errs.create({
      message: 'A flavor is required.'
    }), Array.prototype.slice.call(arguments).pop());
  }
  // Check for instance
  if (typeof instance === 'function' || typeof instance === 'undefined') {
    return errs.handle(errs.create({
      message: 'An instance is required.'
    }), Array.prototype.slice.call(arguments).pop());
  }

  if (!(flavor instanceof Flavor)) {
    return errs.handle(errs.create({
      message: 'A valid flavor is required.'
    }), Array.prototype.slice.call(arguments).pop());
  }
  //@todo: Check if the new flavor are different from the old.

  var instanceId = instance instanceof Instance ? instance.id : instance;

  var resizeOptions = {
    method: 'POST',
    path: 'instances/' + instanceId + '/action',
    body: {
      resize: {
        flavorRef: flavor.href
      }
    }
  };

  this._request(resizeOptions, function (err, body, response) {
    if (err) {
      return callback(err);
    }

    if (response.statusCode === 202) {
      return callback(null);
    }
    return errs.handle(errs.create({
      message: 'Bad response from resize action.'
    }), callback);
  });
};

// Resize the volume size of the database instance.
// You can use this to change the size of the volume for a database instance.
// ### @instance {string | Object} The ID of the istance of a instance of Instance class (required)
// ### @newSize  {Number} The new size for the volume (require)
// ### @callback {Function} Function to continue, no params are passed.
exports.setVolumeSize = function setVolumeSize(instance, newSize, callback) {
  // Check for instance
  if (typeof instance === 'function' || typeof instance === 'undefined') {
    return errs.handle(errs.create({
      message: 'An instance is required.'
    }), Array.prototype.slice.call(arguments).pop());
  }
  // Check for the volume size
  if (typeof newSize === 'function' || typeof newSize === 'undefined') {
    return errs.handle(errs.create({
      message: 'An correct volume size is required.'
    }), Array.prototype.slice.call(arguments).pop());
  }
  if (newSize > 10 || newSize < 1) {
    return errs.handle(errs.create({
      message: 'An correct volume size is required.'
    }), Array.prototype.slice.call(arguments).pop());
  }

  var instanceId = instance instanceof Instance ? instance.id : instance;

  var resizeOptions = {
    method: 'POST',
    path: 'instances/' + instanceId + '/action',
    body: {
      resize: {
        volume: { size: newSize }
      }
    }
  };

  this._request(resizeOptions, function (err, body, response) {
    if (err) {
      return callback(err);
    }

    if (response.statusCode === 202) {
      return callback(null);
    }
    return errs.handle(errs.create({
      message: 'Bad response from resize action.'
    }), callback);
  });
};