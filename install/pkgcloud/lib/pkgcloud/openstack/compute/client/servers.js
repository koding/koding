/*
 * servers.js: Instance methods for working with servers from OpenStack Cloud
 *
 * (C) 2013 Nodejitsu Inc.
 *
 */
var request  = require('request'),
    base     = require('../../../core/compute'),
    pkgcloud = require('../../../../../lib/pkgcloud'),
    errs     = require('errs'),
    urlJoin  = require('url-join'),
    util     = require('util'),
    _        = require('underscore'),
    Server   = require('../server').Server,
    compute  = pkgcloud.providers.openstack.compute;

var _urlPrefix = '/servers';

/**
 * client._doServerAction
 *
 * @description exported helper function that is wrapped by a number of other more
 * specific functions. Calls the standard server action api for any manner of tasks
 *
 * @param {object|String}   server    The server or serverId to get volumes for
 * @param {object}          body      The body of the server action to perform
 * @param {function}        callback
 * @returns {*}
 */
exports._doServerAction = function(server, body, callback) {
  var self = this,
      serverId = server instanceof Server ? server.id : server;

  var actionOptions = {
    method: 'POST',
    path: urlJoin(_urlPrefix, serverId, 'action'),
    body: body
  };

  return self._request(actionOptions, function (err, body, res) {
    return callback(err, body, res);
  });
};

/**
 * client.getServers
 *
 * @description get the list of servers for the current account
 *
 * @param {object|Function}   [options]     A set of options for the getServers call
 * @param {function}          callback      f(err, servers) where servers is an array of Server
 * @returns {*}
 */
exports.getServers = function getServers(options, callback) {
  var self = this;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  var requestOptions = {
    path: urlJoin(_urlPrefix, 'detail')
  };

  requestOptions.qs = _.pick(options,
    'image',
    'flavor',
    'name',
    'status',
    'marker',
    'limit',
    'changes-since');

  return this._request(requestOptions, function (err, body) {
    if (err) {
      return callback(err);
    }
    if (!body || !body.servers) {
      return callback(new Error('Unexpected empty response'));
    }
    else {
      return callback(null, body.servers.map(function (result) {
        return new compute.Server(self, result);
      }));
    }
  });
};

/**
 * client.createServer
 *
 * @description Creates a server with the specified options. The flavor properties
 * of the options can be instances of Flavor OR ids to those entities in OpenStack.

 * @param {object}          details         the details to create this server
 * @param {String}          details.name    the name of the new server
 * @param {Object|String}   details.flavor  the flavor or flavorId for the new server
 * @param {Object|String}   details.image   the image or imageId for the new server
 * @param {Object}          [details.networks]    optional networking configuration
 * @param {Object}          [details.keyname]     optional keyname configuration
 * @param {Object}          [details.personality] optional personality configuration
 * @param {Object}          [details.metadata]    optional metadata configuration
 * @param callback
 * @returns {request|*}
 */
exports.createServer = function createServer(details, callback) {
  if (typeof details === 'function') {
    callback = details;
    details = {};
  }

  details = details || {};

  if (!validateProperties(['flavor', 'image', 'name'], details,
    'options.%s is a required argument.', callback)) {
    return;
  }

  var self = this,
    createOptions = {
      method: 'POST',
      path: _urlPrefix,
      body: {
        server: _.pick(details, ['name', 'metadata', 'personality'])
      }
    };

  if (details.flavor) {
    createOptions.body.server.flavorRef = details.flavor instanceof base.Flavor
      ? details.flavor.id
      : details.flavor;
  }

  if (details.image) {
    createOptions.body.server.imageRef = details.image  instanceof base.Image
      ? details.image.id
      : details.image;
  }

  if (details.networks) {
    createOptions.body.server.networks = details.networks;
  }

  if (details.keyname) {
    createOptions.body.server.key_name = details.keyname;
  }

  if (details.securityGroups) {
    createOptions.body.server.security_groups = details.securityGroups;
  }

  return this._request(createOptions, function (err, body) {
    if (err) {
      return callback(err);
    }

    if (!body || !body.server) {
      return new Error('Server not passed back from OpenStack.');
    }

    callback(null, new compute.Server(self, {
      id: body.server.id,
      name: details.name,
      adminPass: body.server.adminPass,
      flavorId: body.server.flavorRef,
      imageId: body.server.imageRef,
      personality: body.server.personality
    }));
  });
};

/**
 * client.getServer
 *
 * @description Gets a server from the account
 *
 * @param {String|object}   server    The server or serverId to fetch
 * @param {Function}        callback
 * @returns {request|*}
 */
exports.getServer = function getServer(server, callback) {
  var self = this,
      serverId = server instanceof base.Server ? server.id : server;

  return this._request({
    path: urlJoin(_urlPrefix, serverId)
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    if (!body.server) {
      return new Error('Unexpected empty response');
    }
    else {
      callback(null, new compute.Server(self, body.server), res);
    }
  });
};

/**
 * client.destroyServer
 *
 * @description Delete a server
 *
 * @param {String|object}   server    The server or serverId to delete
 * @param {Function}        callback
 * @returns {request|*}
 */
exports.destroyServer = function destroyServer(server, callback) {
  var serverId = server instanceof base.Server ? server.id : server;

  return this._request({
    method: 'DELETE',
    path: urlJoin(_urlPrefix, serverId)
  }, function (err) {
    return err
      ? callback(err)
      : callback(err, { ok: serverId });
  });
};

/**
 * client.rebootServer
 *
 * @description Reboot the provider server
 *
 * @param {String|object}   server      The server or serverId to reboot
 * @param {object}          [options]   Optionally determine if it's a hard or soft reboot
 * @param {String}          [options.type]  HARD or SOFT reboot. Default is SOFT
 * @param {Function}        callback
 * @returns {*}
 */
exports.rebootServer = function rebootServer(server, options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  options.type = options.type ? options.type.toUpperCase() : 'SOFT';

  return this._doServerAction.call(this, server, { reboot: options }, callback);
};

/**
 * client.rebuildServer
 *
 * @description Rebuild the provider server
 *
 * @param {String|object}   server      The server or serverId to rebuild
 * @param {String|object}   image       The image or imageId to use in the rebuild
 * @param {Function}        callback
 * @returns {*}
 */
exports.rebuildServer = function rebootServer(server, image, callback) {
  var imageId = image instanceof base.Image ? image.id : image;

  this._doServerAction.call(this, server, {
    rebuild: {
      imageRef: imageId
    }
  }, callback);
};

/**
 * client.resizeServer
 *
 * @description Resize the provider server
 *
 * @param {String|object}   server      The server or serverId to resize
 * @param {String|object}   flavor      The flavor or flavorId to use in the resize
 * @param {Function}        callback
 * @returns {*}
 */
exports.resizeServer = function rebootServer(server, flavor, callback) {
  var flavorId = flavor instanceof base.Flavor ? flavor.id : flavor;

  this._doServerAction.call(this, server, {
    resize: {
      flavorRef: flavorId
    }
  }, callback);
};

/**
 * client.confirmServerResize
 *
 * @description Confirm the resize operation for the provided server
 *
 * @param {String|object}   server      The server or serverId
 * @param {Function}        callback
 * @returns {*}
 */
exports.confirmServerResize = function (server, callback) {
  this._doServerAction.call(this, server, { confirmResize: null }, callback);
};

/**
 * client.revertServerResize
 *
 * @description Revert the resize operation for the provided server
 *
 * @param {String|object}   server      The server or serverId
 * @param {Function}        callback
 * @returns {*}
 */
exports.revertServerResize = function (server, callback) {
  this._doServerAction.call(this, server, { revertResize: null }, callback);
};

/**
 * client.renameServer
 *
 * @description Rename the provided server
 *
 * @param {String|object}   server      The server or serverId
 * @param {String}          name        The new name for the server
 * @param {Function}        callback
 * @returns {*}
 */
exports.renameServer = function (server, name, callback) {
  var serverId = server instanceof base.Server ? server.id : server;

  this._request({
    method: 'PUT',
    path: urlJoin(_urlPrefix, serverId),
    body: { server: { name: name } }
  }, function (err) {
    return callback(err);
  });
};

/**
 * client.getServerAddresses
 *
 * @description Get the ip addresses for the provided server
 *
 * @param {String|object}   server      The server or serverId
 * @param {String}          [type]      Optionally provide the type of addresses by network label
 * @param {Function}        callback
 * @returns {*}
 */
exports.getServerAddresses = function (server, type, callback) {
  var serverId = server instanceof base.Server ? server.id : server;

  if (!callback && typeof type === 'function') {
    callback = type;
    type = '';
  }

  var options = {
    path: urlJoin(_urlPrefix, serverId, 'ips')
  };

  if (type) {
    options.path = urlJoin(options.path, type);
  }

  this._request(options, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body.addresses || body);
  });
};

/**
 * validateProperties
 *
 * @description local helper function for validating arguments
 *
 * @param {Array}       required      The list of required properties
 * @param {object}      options       The options object to validate
 * @param {String}      formatString  String formatter for the error message
 * @param {Function}    callback
 * @returns {boolean}
 */
function validateProperties(required, options, formatString, callback) {
  return !required.some(function (item) {
    if (typeof(options[item]) === 'undefined') {
      errs.handle(
        errs.create({ message: util.format(formatString, item) }),
        callback
      );
      return true;
    }
    return false;
  });
}
