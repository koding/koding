/*
 * virtual-interfacesv2.js Implementation of Rackspace os-virtual-interfacesv2 extension
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 *
 */

var Server = require('../../server').Server,
    urlJoin = require('url-join'),
    _ = require('underscore');

var _servers = 'servers',
    _extension = 'os-virtual-interfacesv2';

/**
 * client.getVirtualInterfaces
 *
 * @description get the virtual interfaces for a specific instance
 *
 * @param {String|object}   server    the server or serverId to get the interfaces for
 * @param {Function}        callback  f(err, interfaces) where interfaces is an array of interfaces
 * @returns {*}
 */
exports.getVirtualInterfaces = function (server, callback) {
  var serverId = server instanceof Server ? server.id : server;

  return this._request({
    path: urlJoin(_servers, serverId, _extension)
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body.virtual_interfaces);
  });
};

/**
 * client.createVirtualInterface
 *
 * @description Create a new virtual interface for a provided instance and network
 *
 * @param {String|object}   server    the server or serverId to add the interface to
 * @param {String|object}   network   The network or networkId
 * @param callback
 */
exports.createVirtualInterface = function (server, network, callback) {
  var serverId = server instanceof Server ? server.id : server,
      networkId = (typeof network === 'object') ? network.id : network;

  return this._request({
    method: 'POST',
    path: urlJoin(_servers, serverId, _extension),
    body: {
      virtual_interface: {
        network_id: networkId
      }
    }
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body.virtual_interfaces);
  });
};

/**
 * client.deleteVirtualInterface
 *
 * @description Delete a virtual interface from a server
 *
 * @param {String|object}   server    the server or serverId to delete the interface from
 * @param {String|object}   network   The network or networkId
 * @param {Function}        callback
 * @returns {*}
 */
exports.deleteVirtualInterface = function deleteNetwork(server, network, callback) {
  var serverId = server instanceof Server ? server.id : server,
      networkId = (typeof network === 'object') ? network.id : network;

  return this._request({
    path: urlJoin(_servers, serverId, _extension, networkId),
    method: 'DELETE'
  }, function (err) {
    return callback(err);
  });
};




