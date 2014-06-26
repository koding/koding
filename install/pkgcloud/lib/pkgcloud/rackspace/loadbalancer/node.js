/*
 * node.js: Rackspace Cloud LoadBalancer Node
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    base = require('../../core/loadbalancer/node'),
    _ = require('underscore');

var Node = exports.Node = function Node(client, details) {
  base.Node.call(this, client, details);
};

utile.inherits(Node, base.Node);

Node.prototype._setProperties = function (details) {
  var self = this;

  self.id = details.id;
  self.loadBalancerId = (typeof details.loadBalancerId === 'string')
    ? parseInt(details.loadBalancerId) : details.loadBalancerId;
  self.type = details.type;
  self.port = details.port;
  self.weight = details.weight;
  self.status = details.status;
  self.condition = details.condition;
  self.address = details.address;
};

Node.prototype.toJSON = function () {
  return _.pick(this, ['id', 'loadBalancerId', 'type', 'port', 'weight', 'status',
    'condition', 'address']);
};
