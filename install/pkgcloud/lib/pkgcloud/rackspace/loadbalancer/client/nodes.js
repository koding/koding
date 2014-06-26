/*
 * nodes.js: Rackspace loadbalancer client loadBalancers functionality
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var base = require('../../../core/dns'),
    urlJoin = require('url-join'),
    pkgcloud = require('../../../../../lib/pkgcloud'),
    errs = require('errs'),
    _ = require('underscore'),
    lb = pkgcloud.providers.rackspace.loadbalancer;

var _urlPrefix = 'loadbalancers';

module.exports = {

  /**
   * client.getNodes
   *
   * @description get an array of nodes for the provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getNodes: function (loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'nodes')
    }, function (err, body, res) {
      if (err) {
        return callback(err);
      }

      else if (!body || !body.nodes) {
        return callback(new Error('Unexpected empty response'));
      }

      else {
        return callback(null, body.nodes.map(function (node) {
          return new lb.Node(self,
            _.extend(node, { loadBalancerId: loadBalancerId }));
        }), res);
      }
    });
  },

  /**
   * client.addNodes
   *
   * @description add a node or array of nodes to the provided load balancer. Each of the addresses must be unique to this load balancer.
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {Object|Array}    nodes             list of nodes to add
   * @param {function}        callback
   *
   * Sample node
   *
   * {
   *    address: '192.168.10.1',
   *    port: 80,
   *    condition: 'ENABLED', // also supports 'DISABLED' & 'DRAINING'
   *    type: 'PRIMARY' // use 'SECONDARY' as a fail over node
   * }
   *
   */
  addNodes: function(loadBalancer, nodes, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    if (!Array.isArray(nodes)) {
      nodes = [ nodes ];
    }

    var postOptions = {
      path: urlJoin(_urlPrefix, loadBalancerId, 'nodes'),
      method: 'POST',
      body: { nodes: [] }
    };

    postOptions.body.nodes = _.map(nodes, function(node) {
      return _.pick(node, ['address', 'port', 'condition', 'type', 'weight']);
    });

    self._request(postOptions, function (err, body, res) {
      if (err) {
        return callback(err);
      }

      else if (!body || !body.nodes) {
        return callback(new Error('Unexpected empty response'));
      }

      else {
        return callback(null, body.nodes.map(function (node) {
          return new lb.Node(self,
            _.extend(node, { loadBalancerId: loadBalancerId }));
        }), res);
      }
    });
  },

  /**
   * client.updateNode
   *
   * @description update a node condition, type, or weight
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {Object}          node              the node to update
   * @param {function}        callback
   */
  updateNode: function(loadBalancer, node, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    if (!(node instanceof lb.Node) && (typeof node !== 'object')) {
      throw new Error('node is require argument and must be an object');
    }

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'nodes', node.id),
      method: 'PUT',
      body: {
        node: _.pick(node, ['condition', 'type', 'weight'])
      }
    }, function (err) {
      callback(err);
    });
  },

  /**
   * client.removeNode
   *
   * @description remove a node from a load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {Object}          node              the node or nodeId to remove
   * @param {function}        callback
   */
  removeNode: function (loadBalancer, node, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer,
        nodeId =
          node instanceof lb.Node ? node.id : node;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'nodes', nodeId),
      method: 'DELETE'
    }, function (err) {
      callback(err);
    });
  },

  /**
   * client.removeNodes
   *
   * @description remove an array of nodes or nodeIds from a load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {Array}           nodes             the nodes or nodeIds to remove
   * @param {function}        callback
   */
  removeNodes: function (loadBalancer, nodes, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    // check for valid inputs
    if (!nodes || nodes.length === 0 || !Array.isArray(nodes)) {
      throw new Error('nodes must be an array of Node or nodeId');
    }

    // support passing either the javascript object or an array of ids
    var list = nodes.map(function (item) {
      return (typeof item === 'object') ? item.id : item;
    });

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'nodes', '?id=' + list.join('&id=')),
      method: 'DELETE'
    }, function (err) {
      callback(err);
    });
  },

  /**
   * client.getNodeServiceEvents
   *
   * @description retrieve a list of events associated with the activity
   * between the node and the load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getNodeServiceEvents: function (loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'nodes', 'events')
    }, function (err, body) {
      return err
        ? callback(err)
        : callback(err, body.nodeServiceEvents);
    });
  }
};