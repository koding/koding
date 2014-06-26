/*
 * networks-base.js Implementation of OpenStack os-networks base extension
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 *
 */

var urlJoin = require('url-join'),
    _ = require('underscore');

exports.createNetworkExtension = function(prefix) {
  return {
    _extension: prefix,

    /**
     * client.getNetworks
     *
     * @description Display the currently available networks
     *
     * @param {Function}    callback    f(err, networks) where networks is an array of networks
     * @returns {*}
     */
    getNetworks: function (callback) {
      return this._request({
        path: this._extension
      }, function (err, body, res) {
        return err
          ? callback(err)
          : callback(null, body.networks, res);
      });
    },

    /**
     * client.getNetwork
     *
     * @description Get the details for a specific network
     *
     * @param {String|object}   network   The network or networkId to get
     * @param {Function}        callback
     * @returns {*}
     */
    getNetwork: function (network, callback) {
      var networkId = (typeof network === 'object') ? network.id : network;

      return this._request({
        path: urlJoin(this._extension, networkId)
      }, function (err, body) {
        return err
          ? callback(err)
          : callback(null, body.network);
      });
    },

    /**
     * client.createNetwork
     *
     * @description Create a new user defined network.
     *
     * @param {object}      options
     * @param {String}      options.label         The name of the new network
     * @param {String}      [options.cidr]        The IP block to allocate for the network
     * @param {String}      [options.bridge]      VIFs on this network are connected to this bridge.
     * @param {String}      [options.bridge_interface]      The bridge is connected to this interface.
     * @param {String}      [options.multi_host]
     * @param {String}      [options.vlan]        VLAN Id
     * @param {String}      [options.cidr_v6]     IPv6 Subnet
     * @param {String}      [options.dns1]        DNS 1 for the Network
     * @param {String}      [options.dns2]        DNS 2 for the Network
     * @param {String}      [options.gateway]     IPv4 Gateway
     * @param {String}      [options.gateway_v6]  IPv6 Gateway
     * @param {String}      [options.project_id]
     * @param callback
     */
    createNetwork: function (options, callback) {
      return this._createNetwork(options, ['label', 'cidr', 'bridge',
        'bridge_interface', 'multi_host', 'vlan', 'cidr_v6', 'dns1',
        'dns2', 'gateway', 'gateway_v6', 'project_id'], callback);
    },

    /**
     * client._createNetwork
     *
     * @description helper function for allowing a different set of options to be passed to the
     * remote API.
     *
     * @param options
     * @param {Array}       properties      Array of properties to be used when building the payload
     * @param callback
     * @returns {*}
     * @private
     */
    _createNetwork: function (options, properties, callback) {
      return this._request({
        method: 'POST',
        path: this._extension,
        body: {
          network: _.pick(options, properties)
        }
      }, function (err, body) {
        return err
          ? callback(err)
          : callback(null, body.network);
      });
    },

    /**
     * client.addNetwork
     *
     * @description Add an existing network to a project
     *
     * @param {String|object}   network   The network or networkId to add
     * @param {Function}        callback
     */
    addNetwork: function (network, callback) {
      var networkId = (typeof network === 'object') ? network.id : network;

      return this._request({
        path: urlJoin(this._extension, 'add'),
        method: 'POST',
        body: {
          id: networkId
        }
      }, function (err) {
        return callback(err);
      });
    },

    /**
     * client.addNetworkToHost
     *
     * @description Add a specific network to a host
     *
     * @param {String|object}     network     The network or networkId for the action
     * @param {object}            host        The host to associate with the network
     * @param callback
     * @returns {*}
     * @private
     */
    addNetworkToHost: function (network, host, callback) {
      return this._doNetworkAction(network, {
        associate_host: host
      }, callback);
    },

    /**
     * client.removeNetworkFromHost
     *
     * @description Disassociate a network from a provided host
     *
     * @param {String|object}     network     The network or networkId for the action
     * @param {object}            host        The host to remove the network from
     * @param callback
     * @returns {*}
     * @private
     */
    removeNetworkFromHost: function (network, host, callback) {
      return this._doNetworkAction(network, {
        disassociate_host: null
      }, callback);
    },

    /**
     * client.disassociateNetworkFromProject
     *
     * @description Disassociate a network from a project
     *
     * @param {String|object}     network     The network or networkId for the action
     * @param callback
     * @returns {*}
     * @private
     */
    disassociateNetworkFromProject: function (network, callback) {
      return this._doNetworkAction(network, {
        disassociate: null
      }, callback);
    },

    /**
     * client.disassociateProjectFromNetwork
     *
     * @description Disassociate a project from a network
     *
     * @param {String|object}     network     The network or networkId for the action
     * @param callback
     * @returns {*}
     * @private
     */
    disassociateProjectFromNetwork: function (network, callback) {
      return this._doNetworkAction(network, {
        disassociate_project: null
      }, callback);
    },

    /**
     * client._doNetworkAction
     *
     * @description Helper function to expose generalized network action capabilities
     *
     * @param {String|object}     network     The network or networkId for the action
     * @param {object}            payload     The specific payload for the action
     * @param callback
     * @returns {*}
     * @private
     */
    _doNetworkAction: function (network, payload, callback) {
      var networkId = (typeof network === 'object') ? network.id : network;

      return this._request({
        path: urlJoin(this._extension, networkId, 'action'),
        method: 'POST',
        body: payload
      }, function (err) {
        return callback(err);
      });
    },

    /**
     * client.deleteNetwork
     *
     * @description Delete a network from the current account
     *
     * @param {String|object}   network   The network or networkId to get
     * @param {Function}        callback
     * @returns {*}
     */
    deleteNetwork: function deleteNetwork(network, callback) {
      var networkId = (typeof network === 'object') ? network.id : network;

      return this._request({
        path: urlJoin(this._extension, networkId),
        method: 'DELETE'
      }, function (err) {
        return callback(err);
      });
    }
  }
};





