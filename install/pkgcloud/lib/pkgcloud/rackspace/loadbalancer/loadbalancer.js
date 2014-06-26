/*
 * loadbalancer.js: Rackspace Cloud LoadBalancer LoadBalancer
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    base = require('../../core/loadbalancer/loadbalancer'),
    _ = require('underscore');

var LoadBalancer = exports.LoadBalancer = function LoadBalancer(client, details) {
  base.LoadBalancer.call(this, client, details);
};

utile.inherits(LoadBalancer, base.LoadBalancer);

LoadBalancer.prototype._setProperties = function (details) {
  var self = this;

  self.id = details.id;
  self.name = details.name;
  self.protocol = details.protocol;
  self.port = details.port;
  self.algorithm = details.algorithm;
  self.cluster = details.cluster;
  self.status = details.status;
  self.timeout = details.timeout;
  self.halfClosed = details.halfClosed;
  self.nodes = details.nodes || [];
  self.virtualIps = details.virtualIps || [];
  self.sourceAddresses = details.sourceAddresses;
  self.httpsRedirect = details.httpsRedirect;
  self.connectionLogging = details.connectionLogging;
  self.contentCaching = details.contentCaching;
  self.nodeCount = details.nodeCount || (details.nodes ? details.nodes.length : 0);
  self.created = details.created;
  self.updated = details.updated;
};

/// Nodes

LoadBalancer.prototype.refresh = function(callback) {
  var self = this;
  return self.client.getLoadBalancer(this, function (err, server) {
    if (err) {
      callback(err);
      return;
    }

    self._setProperties(server);
    callback(err, self);
  });
};

LoadBalancer.prototype.getNodes = function(callback) {
  this.client.getNodes(this, callback);
};

LoadBalancer.prototype.addNode = function(node, callback) {
  this.client.addNodes(this, [ node ], callback);
};

LoadBalancer.prototype.addNodes = function(nodes, callback) {
  this.client.addNodes(this, nodes, callback);
};

LoadBalancer.prototype.updateNode = function(node, callback) {
  this.client.updateNode(this, node, callback);
};

LoadBalancer.prototype.removeNode = function (node, callback) {
  this.client.removeNode(this, node, callback);
};

LoadBalancer.prototype.removeNodes = function(nodes, callback) {
  this.client.removeNodes(this, nodes, callback);
};

LoadBalancer.prototype.getNodeServiceEvents = function (callback) {
  this.client.getNodeServiceEvents(this, callback);
};

/// Virtual IPs

LoadBalancer.prototype.getVirtualIps = function (callback) {
  this.client.getVirtualIps(this, callback);
};

LoadBalancer.prototype.addIPV6VirtualIp = function (callback) {
  this.client.addIPV6VirtualIp(this, callback);
};

LoadBalancer.prototype.removeVirtualIp = function (virtualIp, callback) {
  this.client.removeVirtualIp(this, virtualIp, callback);
};

/// SSL Config

LoadBalancer.prototype.getSSLConfig = function (callback) {
  this.client.getSSLConfig(this, callback);
};

LoadBalancer.prototype.updateSSLConfig = function (details, callback) {
  this.client.updateSSLConfig(this, details, callback);
};

LoadBalancer.prototype.removeSSLConfig = function (callback) {
  this.client.removeSSLConfig(this, callback);
};

/// Access List

LoadBalancer.prototype.getAccessList = function (callback) {
  this.client.getAccessList(this, callback);
};

LoadBalancer.prototype.addAccessList = function (accessList, callback) {
  this.client.addAccessList(this, accessList, callback);
};

LoadBalancer.prototype.deleteAccessListItem = function (accessListItem, callback) {
  this.client.deleteAccessListItem(this, accessListItem, callback);
};

LoadBalancer.prototype.deleteAccessList = function (accessList, callback) {
  this.client.deleteAccessList(this, accessList, callback);
};

LoadBalancer.prototype.resetAccessList = function (callback) {
  this.client.resetAccessList(this, callback);
};

/// Health Monitor

LoadBalancer.prototype.getHealthMonitor = function (callback) {
  this.client.getHealthMonitor(this, callback);
};

LoadBalancer.prototype.updateHealthMonitor = function (details, callback) {
  this.client.updateHealthMonitor(this, details, callback);
};

LoadBalancer.prototype.removeHealthMonitor = function (callback) {
  this.client.removeHealthMonitor(this, callback);
};

/// Session Persistence

LoadBalancer.prototype.getSessionPersistence = function (callback) {
  this.client.getSessionPersistence(this, callback);
};

LoadBalancer.prototype.enableSessionPersistence = function (type, callback) {
  this.client.enableSessionPersistence(this, type, callback);
};

LoadBalancer.prototype.disableSessionPersistence = function (callback) {
  this.client.disableSessionPersistence(this, callback);
};

/// Connection Logging

LoadBalancer.prototype.getConnectionLoggingConfig = function (callback) {
  this.client.getConnectionLoggingConfig(this, callback);
};

LoadBalancer.prototype.enableConnectionLogging = function (callback) {
  this.client.updateConnectionLogging(this, true, callback);
};

LoadBalancer.prototype.disableConnectionLogging = function (callback) {
  this.client.updateConnectionLogging(this, false, callback);
};

/// Connection Throttle

LoadBalancer.prototype.getConnectionThrottleConfig = function (callback) {
  this.client.getConnectionThrottleConfig(this, callback);
};

LoadBalancer.prototype.updateConnectionThrottle = function (details, callback) {
  this.client.updateConnectionThrottle(this, details, callback);
};

LoadBalancer.prototype.disableConnectionThrottle = function (callback) {
  this.client.disableConnectionThrottle(this, callback);
};

/// Content Caching

LoadBalancer.prototype.getContentCachingConfig = function (callback) {
  this.client.getContentCachingConfig(this, callback);
};

LoadBalancer.prototype.enableContentCaching = function (callback) {
  this.client.updateContentCaching(this, true, callback);
};

LoadBalancer.prototype.disableContentCaching = function (callback) {
  this.client.updateContentCaching(this, false, callback);
};

/// Error Page

LoadBalancer.prototype.getErrorPage = function (callback) {
  this.client.getErrorPage(this, callback);
};

LoadBalancer.prototype.setErrorPage = function (content, callback) {
  this.client.setErrorPage(this, content, callback);
};

LoadBalancer.prototype.deleteErrorPage = function (callback) {
  this.client.deleteErrorPage(this, callback);
};

/// Stats & Usage

LoadBalancer.prototype.getStats = function (callback) {
  this.client.getStats(this, callback);
};

LoadBalancer.prototype.getCurrentUsage = function (callback) {
  this.client.getCurrentUsage(this, callback);
};

LoadBalancer.prototype.getHistoricalUsage = function (startTime, endTime, callback) {
  this.client.getHistoricalUsage(this, startTime, endTime, callback);
};

LoadBalancer.prototype.toJSON = function () {
  return _.pick(this, ['id', 'name', 'protocol', 'port', 'algorithm', 'halfClosed',
    'cluster', 'sourceAddresses', 'httpsRedirect', 'connectionLogging', 'contentCaching',
    'status', 'timeout', 'nodes', 'virtualIps', 'nodeCount', 'created', 'updated']);
};
