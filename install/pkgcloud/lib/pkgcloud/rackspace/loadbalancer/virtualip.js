/*
 * virtualip.js: Instance of a rackspace cloud loadbalancer virtual IP
 *
 * (C) 2013 Ken Perkins
 *
 * MIT LICENSE
 *
 */

var VirtualIp = function (details) {
  if (!details) {
    throw new Error('VirtualIp must be constructed with at-least basic details.')
  }

  this._setProperties(details);
};

VirtualIp.prototype = {

  /**
   * @name VirtualIp._setProperties
   *
   * @description Loads the properties of an object into this instance
   *
   * @param {Object}      details     the details to load
   */
  _setProperties: function (details) {
    this.id = details.id;
    this.address = details.address;
    this.type = details.type;
    this.ipVersion = details.ipVersion;
  }
};

exports.VirtualIp = VirtualIp;

exports.VirtualIpTypes = {
  PUBLIC: 'PUBLIC',
  SERVICENET: 'SERVICENET'
};