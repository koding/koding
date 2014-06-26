/*
 * networksv2.js Implementation of Rackspace os-networksv2 extension
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 *
 */

var networks = require('../../../../openstack/compute/client/extensions/networks-base');

// Setup to copy the necessary functions from the standard openstack extension

module.exports = networks.createNetworkExtension('os-networksv2');

/**
 * os-networksv2 is a Rackspace specific extension that is based off of the openstack
 * os-networks extension. As a result, we inherit module.exports from the os-network extension,
 * make chanages where appropriate, and then delete methods that are not supported.
 *
 * The following methods are included without modification:
 *
 * client.getNetworks
 * client.getNetwork
 * client.deleteNetwork
 *
 * The following method is modified from the original:
 *
 * client.createNetwork
 *
 * Lastly, these methods are not part of the os-networksv2 extension:
 *
 * client.addNetwork
 * client.addNetworkToHost
 * client.removeNetworkFromHost
 * client.disassociateNetworkFromProject
 * client.disassociateProjectFromNetwork
 *
 */

delete exports.addNetwork;
delete exports.addNetworkToHost;
delete exports.removeNetworkFromHost;
delete exports.disassociateNetworkFromProject;
delete exports.disassociateProjectFromNetwork;
delete exports._doNetworkAction;

/**
 * client.createNetwork
 *
 * @description Create a new user defined network.
 *
 * @param {object}      options
 * @param {String}      options.label     The name of the new network
 * @param {String}      [options.cidr]    The IP block to allocate for the network
 * @param callback
 */
exports.createNetwork = function (options, callback) {
  return this._createNetwork(options, ['label', 'cidr'], callback);
};





