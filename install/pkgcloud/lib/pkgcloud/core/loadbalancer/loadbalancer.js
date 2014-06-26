/*
 * loadbalancer.js: Base record from which all pkgcloud loadbalancers inherit from
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    model = require('../base/model');

var LoadBalancer = exports.LoadBalancer = function (client, details) {
  model.Model.call(this, client, details);
};

utile.inherits(LoadBalancer, model.Model);

LoadBalancer.prototype.create = function (callback) {
  return this.client.createLoadBalancer(this, callback);
};

LoadBalancer.prototype.get = function (callback) {
  return this.client.getLoadBalancer(this, callback);
};

LoadBalancer.prototype.update = function (callback) {
  return this.client.updateLoadBalancer(this, callback);
};

LoadBalancer.prototype.destroy = function (callback) {
  return this.client.deleteLoadBalancer(this, callback);
};