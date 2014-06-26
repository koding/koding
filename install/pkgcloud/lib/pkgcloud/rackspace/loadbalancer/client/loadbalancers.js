/*
 * loadbalancers.js: Rackspace loadbalancer client loadBalancers functionality
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
   * @name Client.getLoadBalancers
   *
   * @description get your list of load balancers
   *
   * @param {object|Function}     options     options for the call; not used presently;
   * @param {Function}            callback    handles the callback of your api call
   */
  getLoadBalancers: function (options, callback) {
    var self = this,
        requestOptions = {
          path: _urlPrefix
    };

    if (typeof options === 'function') {
      callback = options;
      options = {};
    }

    self._request(requestOptions, function (err, body, res) {
      if (err) {
        return callback(err);
      }

      else if (!body || !body.loadBalancers) {
        return callback(new Error('Unexpected empty response'));
      }

      else {
        return callback(null, body.loadBalancers.map(function (loadBalancer) {
          return new lb.LoadBalancer(self, loadBalancer);
        }));
      }
    });
  },

  /**
   * client.getLoadBalancer
   *
   * @description Get the details for the provided load balancer Id
   *
   * @param {object|String}   loadBalancer  The loadBalancer or loadBalancer id for the query
   * @param {function}        callback
   * @returns {*}
   */
  getLoadBalancer: function(loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId)
    }, function (err, body, res) {
      if (err) {
        return callback(err);
      }

      else if (!body || !body.loadBalancer) {
        return callback(new Error('Unexpected empty response'));
      }

      else {
        return callback(null, new lb.LoadBalancer(self, body.loadBalancer));
      }
    });
  },

  /**
   * client.createLoadBalancer
   *
   * @description Create a new cloud LoadBalancer. There are a number of options for
   * cloud load balancers; please reference the Rackspace API documentation for more
   * insight into the specific parameter values:
   *
   * http://docs.rackspace.com/loadbalancers/api/v1.0/clb-devguide/content/Create_Load_Balancer-d1e1635.html
   *
   * @param {object}          details   details object for the new load balancer
   * @param {String}          details.name    the name of your load balancer
   * @param {Object}          details.protocol
   * @param {String}          details.protocol.name     protocol name
   * @param {Number}          details.protocol.port     port number
   * @param {Array}           details.virtualIps        array of virtualIps for new LB
   * @param {Array}           [details.nodes]           array of nodes to add
   *
   * For extended option support please see the API documentation
   *
   * @param {function}        callback
   * @returns {*}
   */
  createLoadBalancer: function(details, callback) {
    var self = this,
        createOptions = {
          path: _urlPrefix,
          method: 'POST',
          body: {
            name: details.name,
            nodes: details.nodes || [],
            protocol: details.protocol ? details.protocol.name : '',
            port: details.protocol ? details.protocol.port : '',
            virtualIps: details.virtualIps
          }
        };

    createOptions.body = _.extend(createOptions.body,
      _.pick(details, ['accessList', 'algorithm', 'connectionLogging',
        'connectionThrottle', 'healthMonitor', 'metadata', 'timeout',
        'sessionPersistence']));

    var validationErrors = validateLbInputs(createOptions.body);

    if (validationErrors) {
      return callback(new Error('Errors validating inputs for createLoadBalancer', validationErrors));
    }

    self._request(createOptions, function(err, body) {
      return err
        ? callback(err)
        : callback(err, new lb.LoadBalancer(self, body.loadBalancer));
    });
  },

  /**
   * client.updateLoadBalancer
   *
   * @description updates specific parameters of the load balancer
   *
   * Specific properties updated: name, protocol, port, timeout,
   * algorithm, httpsRedirect and halfClosed
   *
   * @param {Object}        loadBalancer
   * @param {function}      callback
   */
  updateLoadBalancer: function (loadBalancer, callback) {

    if (!(loadBalancer instanceof lb.LoadBalancer)) {
      throw new Error('Missing required argument: loadBalancer');
    }

    var self = this,
      updateOptions = {
        path: urlJoin(_urlPrefix, loadBalancer.id),
        method: 'PUT',
        body:  {}
      };

    updateOptions.body.loadBalancer = _.pick(loadBalancer, ['name', 'protocol',
      'port', 'timeout', 'algorithm', 'httpsRedirect', 'halfClosed']);

    self._request(updateOptions, function (err) {
      callback(err);
    });
  },

  /**
   * client.deleteLoadBalancer
   *
   * @description Deletes the provided load balancer and all configuration information
   *
   * @param {Object}        loadBalancer    the loadBalancer or loadBalancerId
   * @param {function}      callback
   */
  deleteLoadBalancer: function(loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId),
      method: 'DELETE'
    }, function (err) {
      callback(err);
    });
  },

  /// Virtual IP Functionality

  /**
   * client.getVirtualIps
   *
   * @description get the list of virtualIps for the provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getVirtualIps: function (loadBalancer, callback) {
    var self = this,
      loadBalancerId =
        loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'virtualips')
    }, function (err, body) {
      return callback(err, body.virtualIps);
    });
  },

  /**
   * client.addIPV6VirtualIp
   *
   * @description add a public facing IPV6 virtualIP to your load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  addIPV6VirtualIp: function (loadBalancer, callback) {
    var self = this,
      loadBalancerId =
        loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'virtualips'),
      method: 'POST',
      body: {
        ipVersion: 'IPV6',
        type: 'PUBLIC'
      }
    }, function (err, body) {
      return callback(err, body);
    });
  },

  /**
   * client.removeVirtualIp
   *
   * @description remove a virtualIP from a load Balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {Number}          virtualIp         the virtualIp id to remove
   * @param {function}        callback
   */
  removeVirtualIp: function (loadBalancer, virtualIp, callback) {
    var self = this,
      loadBalancerId =
        loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'virtualips', virtualIp),
      method: 'DELETE'
    }, function (err) {
      return callback(err);
    });
  },

  /// SSL Termination

  /**
   * client.getSSLConfig
   *
   * @description gets the current SSL termination config, if any
   *
   * @param {Object}        loadBalancer    the loadBalancer or loadBalancerId
   * @param {function}      callback
   */
  getSSLConfig: function(loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'ssltermination')
    }, function (err, body) {
      return err
        ? callback(err)
        : callback(err, body.sslTermination);
    });
  },

  /**
   * client.updateSSLConfig
   *
   * @description update the SSL configuration for a load balancer
   *
   * @param {Object}        loadBalancer    the loadBalancer or loadBalancerId
   * @param {Object}        details         SSL config to updated
   * @param {Boolean}       details.enabled                 true/false to enable SSL
   * @param {Number}        details.securePort              port number for the SSL service
   * @param {String}        details.privatekey              keyfile for the certificate
   * @param {String}        details.certificate             the certificate to load
   * @param {Boolean}       [details.secureTrafficOnly]     true/false to enable SSL only
   * @param {String}        [details.intermediatecertificate]   optional intermediate cert
   * @param {function}      callback
   */
  updateSSLConfig: function(loadBalancer, details, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    var options = _.pick(details, ['securePort', 'privatekey', 'certificate',
      'intermediateCertificate', 'enabled', 'secureTrafficOnly']);

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'ssltermination'),
      method: 'PUT',
      body: options
    }, function (err) {
      callback(err);
    });
  },

  /**
   * client.removeSSLConfig
   *
   * @description removes and disabled SSL termination
   *
   * @param {Object}        loadBalancer    the loadBalancer or loadBalancerId
   * @param {function}      callback
   */
  removeSSLConfig: function (loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'ssltermination'),
      method: 'DELETE'
    }, function (err, body, res) {
      callback(err);
    });
  },

  /// Access Control Functionality

  /**
   * client.getAccessList
   *
   * @description get the access control list for the provided load balancer
   *
   * @param {Object}          loadBalancer  the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getAccessList: function(loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'accesslist')
    }, function (err, body, res) {
      return callback(err, body.accessList);
    });
  },

  /**
   * client.addAccessList
   *
   * @description Add an entry or array of entries to the load balancer accessList
   *
   * @param {Object}          loadBalancer  the loadBalancer or loadBalancerId
   * @param {Object|Array}    accessList    an object or array of objects to add
   * @param {function}        callback
   *
   * Sample Access List Entry:
   *
   * {
   *    address: '192.168.0.1',
   *    type: 'ALLOW' // optionally use 'DENY'
   * }
   *
   */
  addAccessList: function(loadBalancer, accessList, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    if (!Array.isArray(accessList)) {
      accessList = [ accessList ];
    }

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'accesslist'),
      method: 'POST',
      body: {
        accessList: accessList
      }
    }, function (err) {
      return callback(err);
    });
  },

  /**
   * client.deleteAccessListItem
   *
   * @description remove an entry from a load Balancer accessList
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {Object|Number}   accessListItem    an object or id to remove
   * @param {function}        callback
   */
  deleteAccessListItem: function(loadBalancer, accessListItem, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer,
        accessListItemId = (typeof accessListItem === 'object')
          ? accessListItem.id : accessListItem;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'accesslist', accessListItemId),
      method: 'DELETE'
    }, function (err) {
      return callback(err);
    });
  },

  /**
   * client.deleteAccessList
   *
   * @description remove an array of objects from a LoadBalancer accessList
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {Array}           accessList        an array of objects or ids to remove
   * @param {function}        callback
   */
  deleteAccessList: function(loadBalancer, accessList, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    // check for valid inputs
    if (!accessList || accessList.length === 0 || !Array.isArray(accessList)) {
      throw new Error('accessList must be an array of accessList or accessListId');
    }

    // support passing either the javascript object or an array of ids
    var list = accessList.map(function(item) {
      return (typeof item === 'object') ? item.id : item;
    });

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'accesslist', '?id=' + list.join('&id=')),
      method: 'DELETE'
    }, function (err, body, res) {
      return callback(err);
    });
  },

  /**
   * client.resetAccessList
   *
   * @description completely delete and reset the access list
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  resetAccessList: function (loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'accesslist'),
      method: 'DELETE'
    }, function (err) {
      return callback(err);
    });
  },

  /// Health Monitor Functionality

  /**
   * client.getHealthMonitor
   *
   * @description get the current health monitor configuration for a loadBalancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getHealthMonitor: function(loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'healthmonitor')
    }, function (err, body) {
      return callback(err, body.healthMonitor);
    });
  },

  /**
   * client.updateHealthMonitor
   *
   * @description get the current health monitor configuration for a loadBalancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {Object}          details
   * @param {function}        callback
   *
   * There are two kinds of connection monitors you can enable, CONNECT and HTTP/HTTPS.
   * CONNECT monitors are basically a ping check. HTTP/HTTPS checks
   * are used to validate a HTTP request body/status for specific information.
   *
   * Sample CONNECT details:
   *
   * {
   *    type: 'CONNECT',
   *    delay: 10,
   *    timeout: 10,
   *    attemptsBeforeDeactivation: 3
   * }
   * 
   * Sample HTTP details:
   * 
   * {
   *    type: 'HTTP',
   *    delay: 10,
   *    timeout: 10,
   *    attemptsBeforeDeactivation: 3,
   *    path: '/',
   *    statusRegex: '^[234][0-9][0-9]$',
   *    bodyRegex: '^[234][0-9][0-9]$',
   *    hostHeader: 'myrack.com'
   *  }
   *
   */
  updateHealthMonitor: function(loadBalancer, details, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    if (!details || !details.type) {
      throw new Error('Details is a required option for loadBalancer health monitors');
    }

    var requestOptions = {
      path: urlJoin(_urlPrefix, loadBalancerId, 'healthmonitor'),
      method: 'PUT'
    };

    if (details.type === 'CONNECT') {
      requestOptions.body = {
        attemptsBeforeDeactivation: details.attemptsBeforeDeactivation,
        type: details.type,
        delay: details.delay,
        timeout: details.timeout
      }
    }
    else if (details.type === 'HTTP' || details.type === 'HTTPS') {
      requestOptions.body = {
        attemptsBeforeDeactivation: details.attemptsBeforeDeactivation,
        type: details.type,
        delay: details.delay,
        timeout: details.timeout,
        bodyRegex: details.bodyRegex,
        path: details.path,
        statusRegex: details.statusRegex
      }

      if (details.hostHeader) {
        requestOptions.body.hostHeader = details.hostHeader;
      }
    }
    else {
      throw new Error('Unsupported health monitor type');
    }

    self._request(requestOptions, function (err) {
      return callback(err);
    });
  },

  /**
   * client.removeHealthMonitor
   *
   * @description Remove and disable any health monitors
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  removeHealthMonitor: function(loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'healthmonitor'),
      method: 'DELETE'
    }, function (err) {
      return callback(err);
    });
  },

  /// Session Persistence Functionality

  /**
   * client.getSessionPersistence
   *
   * @description Get the session persistence settings for the provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getSessionPersistence: function (loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'sessionpersistence')
    }, function (err, body) {
      return callback(err, body.sessionPersistence);
    });
  },

  /**
   * client.enableSessionPersistence
   *
   * @description Enable session persistence of the requested type
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {String}          type              HTTP_COOKIE or SOURCE_IP
   * @param {function}        callback
   */
  enableSessionPersistence: function (loadBalancer, type, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    if (!type || (type !== 'HTTP_COOKIE' && type !== 'SOURCE_IP')) {
      throw new Error('Please provide a valid session persistence type');
    }

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'sessionpersistence'),
      method: 'PUT',
      body: {
        sessionPersistence: {
          persistenceType: type
        }
      }
    }, function (err) {
      return callback(err);
    });
  },

  /**
   * client.disableSessionPersistence
   *
   * @description Disable session persistence for the provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  disableSessionPersistence: function (loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'sessionpersistence'),
      method: 'DELETE'
    }, function (err) {
      return callback(err);
    });
  },

  /// Connection Logging Functionality

  /**
   * client.getConnectionLoggingConfig
   *
   * @description get the current connection logging configuratino for the
   * provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getConnectionLoggingConfig: function(loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'connectionlogging')
    }, function (err, body) {
      return callback(err, body.connectionLogging);
    });
  },

  /**
   * client.updateConnectionLogging
   *
   * @description Enable or disable connection logging for the provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {Boolean}         enabled           enable or disable logging
   * @param {function}        callback
   */
  updateConnectionLogging: function(loadBalancer, enabled, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    if (typeof enabled !== 'boolean') {
      throw new Error('enabled must be a boolean value');
    }

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'connectionlogging'),
      method: 'PUT',
      body: {
        connectionLogging: {
          enabled: enabled
        }
      }
    }, function (err) {
      return callback(err);
    });
  },

  /// Connection Throttle Functionality

  /**
   * client.getConnectionThrottleConfig
   *
   * @description get the current connection logging throttle configuration for the
   * provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getConnectionThrottleConfig: function (loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'connectionthrottle')
    }, function (err, body) {
      return callback(err, body.connectionThrottle);
    });
  },

  /**
   * client.updateConnectionThrottle
   *
   * @description update or add a connection throttle for the provided load balancer
   *
   * @param {Object}          loadBalancer  the loadBalancer or loadBalancerId
   * @param {Object}          details       the connection throttle details
   * @param {function}        callback
   *
   * Sample Access List Entry:
   *
   * {
   *    maxConnectionRate: 0, // 0 for unlimited, 1-100000
   *    maxConnections: 10,   // 0 for unlimited, 1-100000
   *    minConnections: 5, // 0 for unlimited, 1-1000 otherwise
   *    rateInterval: 3600 // frequency in seconds at which maxConnectionRate
   *                       // is assessed
   * }
   *
   */
  updateConnectionThrottle: function (loadBalancer, details, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    var options = _.pick(details, ['maxConnectionRate', 'maxConnections',
      'minConnections', 'rateInterval']);

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'connectionthrottle'),
      method: 'PUT',
      body: {
        connectionThrottle: options
      }
    }, function (err) {
      return callback(err);
    });
  },

  /**
   * client.disableConnectionThrottle
   *
   * @description disables connection throttling on the provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  disableConnectionThrottle: function (loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'connectionthrottle'),
      method: 'DELETE'
    }, function (err) {
      return callback(err);
    });
  },

  /// Content Caching Functionality

  /**
   * client.getContentCachingConfig
   *
   * @description get the current content caching configuration for the
   * provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getContentCachingConfig: function (loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'contentcaching')
    }, function (err, body) {
      return callback(err, body.contentCaching);
    });
  },

  /**
   * client.updateContentCaching
   *
   * @description Enable or disable content caching for the provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {Boolean}         enabled           enable or disable logging
   * @param {function}        callback
   */
  updateContentCaching: function (loadBalancer, enabled, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    if (typeof enabled !== 'boolean') {
      throw new Error('enabled must be a boolean value');
    }

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'contentcaching'),
      method: 'PUT',
      body: {
        contentCaching: {
          enabled: enabled
        }
      }
    }, function (err) {
      return callback(err);
    });
  },

  /// Error Page Functionality

  /**
   * client.getErrorPage
   *
   * @description get the error page for the provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getErrorPage: function(loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'errorpage')
    }, function (err, body) {
      if (err) {
        return callback(err);
      }
      else if (!body || !body.errorpage || !body.errorpage.content) {
        return callback(new Error('Unexpected empty response'));
      }
      else {
        return callback(err, body.errorpage.content);
      }
    });
  },

  /**
   * client.setErrorPage
   *
   * @description set the error page for the provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {String}          content           HTML representing your new error page
   * @param {function}        callback
   */
  setErrorPage: function (loadBalancer, content, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'errorpage'),
      method: 'PUT',
      body: {
        errorpage: {
          content: content
        }
      }
    }, function (err) {
      return callback(err);
    });
  },

  /**
   * client.deleteErrorPage
   *
   * @description remove the error page for the provided load balancer
   *
   * @param {Object}          loadBalancer      the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  deleteErrorPage: function (loadBalancer, callback) {
    var self = this,
        loadBalancerId =
          loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'errorpage'),
      method: 'DELETE'
    }, function (err) {
      return callback(err);
    });
  },

  /// Stats & Usage APIs

  /**
   * client.getStats
   *
   * @description get statistics for the provided load balancer
   *
   * @param {Object}        loadBalancer    the loadBalancer or loadBalancerId
   * @param {function}      callback
   */
  getStats: function (loadBalancer, callback) {
    var self = this,
      loadBalancerId =
        loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'stats')
    }, function (err, body) {
      callback(err, body);
    });
  },

  /**
   * client.getBillableLoadBalancers
   *
   * @description gets the billable load balancer within the query limits provided
   *
   * @param {Date|String}     startTime     the start time for the query
   * @param {Date|String}     endTime       the end time for the query
   * @param {object}          [options]
   * @param {object}          [options.limit]
   * @param {object}          [options.offset]
   * @param {function}        callback
   */
  getBillableLoadBalancers: function (startTime, endTime, options, callback) {
    var self = this;

    if (typeof options === 'function') {
      callback = options;
      options = {};
    }

    var requestOpts = {
      path: urlJoin(_urlPrefix, 'billable'),
      qs: {
        startTime: typeof startTime === 'Date' ? startTime.toISOString() : startTime,
        endTime: typeof endTime === 'Date' ? endTime.toISOString() : endTime
      }
    };

    requestOpts.qs = _.extend(requestOpts.qs, _.pick(options, ['offset', 'limit']));

    self._request(requestOpts, function (err, body, res) {
      return callback(err, body.loadBalancers.map(function (loadBalancer) {
        return new lb.LoadBalancer(self, loadBalancer);
      }), res);
    });
  },

  /**
   * client.getAccountUsage
   *
   * @description lists account level usage
   *
   * @param {Date|String}     startTime     the start time for the query
   * @param {Date|String}     endTime       the end time for the query
   * @param {function}        callback
   */
  getAccountUsage: function (startTime, endTime, callback) {
    var self = this;

    self._request({
      path: urlJoin(_urlPrefix, 'usage'),
      qs: {
        startTime: typeof startTime === 'Date' ? startTime.toISOString() : startTime,
        endTime: typeof endTime === 'Date' ? endTime.toISOString() : endTime
      }
    }, function (err, body) {
      return callback(err, body);
    });
  },

  /**
   * client.getHistoricalUsage
   *
   * @description get historical usage data for a provided load balancer. Data available for 90 days of service activity.
   *
   * @param {Object}          loadBalancer  the loadBalancer or loadBalancerId
   * @param {Date|String}     startTime     the start time for the query
   * @param {Date|String}     endTime       the end time for the query
   * @param {function}        callback
   */
  getHistoricalUsage: function (loadBalancer, startTime, endTime, callback) {
    var self = this,
      loadBalancerId =
        loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'usage'),
      qs: {
        startTime: startTime,
        endTime: endTime
      }
    }, function (err, body) {
      return callback(err, body);
    });
  },

  /**
   * client.getCurrentUsage
   *
   * @description get current usage data for a provided load balancer.
   *
   * @param {Object}          loadBalancer  the loadBalancer or loadBalancerId
   * @param {function}        callback
   */
  getCurrentUsage: function (loadBalancer, callback) {
    var self = this,
      loadBalancerId =
        loadBalancer instanceof lb.LoadBalancer ? loadBalancer.id : loadBalancer;

    self._request({
      path: urlJoin(_urlPrefix, loadBalancerId, 'usage', 'current')
    }, function (err, body) {
      return callback(err, body);
    });
  },

  /**
   * client.getAllowedDomains
   *
   * @description gets a list of domains that are available in lieu of IP addresses
   * when adding nodes to a load balancer
   *
   * @param {function}        callback
   */
  getAllowedDomains: function (callback) {
    var self = this;

    self._request({
      path: urlJoin(_urlPrefix, 'alloweddomains')
    }, function (err, body) {
      return callback(err, body.allowedDomains);
    });
  },

  /// Protocols and Algorithms

  /**
   * client.getProtocols
   *
   * @description get a list of supported load balancer protocols
   *
   * @param {function}        callback
   */
  getProtocols: function(callback) {
    var self = this;

    self._request({
      path: urlJoin(_urlPrefix, 'protocols')
    }, function (err, body) {
      return callback(err, body.protocols);
    });
  },

  /**
   * client.getAlgorithms
   *
   * @description get a list of supported load balancer algorithms
   *
   * @param {function}        callback
   */
  getAlgorithms: function (callback) {
    var self = this;

    self._request({
      path: urlJoin(_urlPrefix, 'algorithms')
    }, function (err, body) {
      return callback(err, body.algorithms);
    });
  }
};

// Private function for validation of createLoadBalancer Inputs
var validateLbInputs = function (inputs) {

  var errors = {
    requiredParametersMissing: [],
    invalidInputs: []
  }, response;

  if (!inputs.name) {
    errors.requiredParametersMissing.push('name');
  }

  if (!inputs.nodes) {
    errors.requiredParametersMissing.push('nodes');
  }

  if (!inputs.protocol) {
    errors.requiredParametersMissing.push('protocol');
  }

  if (!inputs.port) {
    errors.requiredParametersMissing.push('port');
  }

  if (!inputs.virtualIps) {
    errors.requiredParametersMissing.push('virtualIps');
  }

  if (inputs.name && inputs.name.length > 128) {
    errors.invalidInputs.push('name exceeds maximum 128 length');
  }

  if (!inputs.protocol ||
    typeof(inputs.protocol) !== 'string' || !lb.Protocols[inputs.protocol]) {
    errors.invalidInputs.push('please specify a valid protocol');
  }

  // TODO Node validation

  if (errors.requiredParametersMissing.length) {
    response ? response.requiredParametersMissing = errors.requiredParametersMissing :
      response = {
        requiredParametersMissing: errors.requiredParametersMissing
      };
  }

  if (errors.invalidInputs.length) {
    response ? response.invalidInputs = errors.invalidInputs :
      response = {
        invalidInputs: errors.invalidInputs
      };
  }

  return response;
};
