/*
 * cdn-containers.js: Instance methods for working with containers from Rackspace Cloudfiles
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var async = require('async'),
  crypto = require('crypto'),
  request = require('request'),
  base = require('../../../openstack'),
  pkgcloud = require('../../../../pkgcloud'),
  _ = require('underscore');

/**
 * client.getFiles
 *
 * @description get the list of containers for an account
 *
 * @param {object|Function}   options
 * @param {Number}            [options.limit]   the number of records to return
 * @param {String}            [options.marker]  the id of the first record to return in the current query
 * @param {Function}          callback
 */
exports.getContainers = function (options, callback) {
  var self = this;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  var getContainerOpts = {
    path: '',
    qs: _.extend({
      format: 'json'
    }, _.pick(options, ['limit', 'marker', 'end_marker']))
  };

  this._request(getContainerOpts, function (err, body) {
    if (err) {
      return callback(err);
    }
    else if (!body || !(body instanceof Array)) {
      return new Error('Malformed API Response')
    }

    if (!options.loadCDNAttributes) {
      return callback(null, body.map(function (container) {
        return new self.models.Container(self, container);
      }));
    }
    else {
      var containers = [];

      async.forEachLimit(body, 10, function (c, next) {
        var container = new self.models.Container(self, c);

        containers.push(container);
        container.refreshCdnDetails(function (err) {
          if (err) {
            return next(err);
          }
          next();
        })
      }, function (err) {
        callback(err, containers);
      });
    }
  });
};

/**
 * client.getContainer
 *
 * @description get the details for a specific container
 *
 * @param {String|object}     container     the container or containerName
 * @param callback
 */
exports.getContainer = function (container, callback) {
  var containerName = container instanceof this.models.Container ? container.name : container,
    self = this;

  this._request({
    method: 'HEAD',
    container: containerName
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }

    self._getCdnContainerDetails(containerName, function (err, details) {
      if (err) {
        return callback(err);
      }

      container = _.extend({}, details, {
        name: containerName,
        count: parseInt(res.headers['x-container-object-count'], 10),
        bytes: parseInt(res.headers['x-container-bytes-used'], 10)
      });

      container.metadata = self.deserializeMetadata(self.CONTAINER_META_PREFIX, res.headers);

      callback(null, new self.models.Container(self, container));
    });
  });
};

/**
 * client.getCdnContainers
 *
 * @description get the list of cdn enabled containers
 *
 * @param {object|Function}   options
 * @param {Number}            [options.limit]   the number of records to return
 * @param {String}            [options.marker]  the id of the first record to return in the current query
 * @param {String}            [options.end_marker]  the id of the last record to return in the current query
 * @param {boolean}           [options.enabled_only]  only get containers which are cdn enabled = true
 * @param {Function}          callback
 */
exports.getCdnContainers = function (options, callback) {
  var self = this;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  var getContainerOpts = {
    path: '',
    serviceType: this.cdnServiceType,
    qs: _.extend({
      format: 'json'
    }, _.pick(options, ['limit', 'marker', 'end_marker']))
  };

  if (options.cdnOnly) {
    getContainerOpts.qs['enabled_only'] = options.cdnOnly;
  }

  this._request(getContainerOpts, function (err, body) {
    return err
      ? callback(err)
      : callback(null, body.map(function (container) {
      //
      // The cdn properties are normally set in response headers
      // when requesting single cdn containers
      //
      container.cdnEnabled = container.cdn_enabled == 'true';
      container.logRetention = container.log_retention == 'true';
      container.cdnUri = container.cdn_uri;
      container.cdnSslUri = container.cdn_ssl_uri;

      return new self.models.Container(self, container);
    }));
  });
};


/**
 * client.getCdnContainer
 *
 * @description get the details for a specific cdn enabled container
 *
 * @param {String|object}     container     the container or containerName
 * @param callback
 */
exports.getCdnContainer = function (container, callback) {
  var self = this;

  this._getCdnContainerDetails(container, function(err, details) {
    return err
      ? callback(err)
      : callback(null, new self.models.Container(self, details));
  });
};

/**
 * client.setCdnEnabled
 *
 * @description enable or disable cdn capabilities on a storage container
 *
 * @param {String|object}     container     the container or containerName
 * @param {object|boolean}    options       an object with options, or boolean to just enable/disable
 * @param {boolean}           options.enabled   enable or disable the cdn capability
 * @param {number}            options.ttl       configure the CDN ttl for this container
 * @param callback
 */
exports.setCdnEnabled = function (container, options, callback) {
  var self = this,
      containerName = container instanceof self.models.Container ? container.name : container,
      enabled = typeof options === 'boolean' ? options : options.enabled;

  if (typeof options === 'function') {
    callback = options;
    options = {};
    enabled = true;
  }

  var cdnOpts = {
    method: 'PUT',
    container: containerName,
    serviceType: this.cdnServiceType,
    headers: {
      'x-cdn-enabled': enabled
    }
  };

  if (options.ttl) {
    cdnOpts.headers['x-ttl'] = options.ttl;
  }

  self._request(cdnOpts, function(err) {
    if (err) {
      return callback(err);
    }

    self.getContainer(containerName, function(err, container) {
      return err
        ? callback(err)
        : callback(err, container);
    });
  });
};

/**
 * client.updateCdnContainer
 *
 * @description update the settings for a cdn container
 *
 * @param {String|object}     container     the container or containerName
 * @param {object}            options
 * @param {boolean}           options.enabled   enable or disable the cdn capability
 * @param {number}            options.ttl       configure the CDN ttl for this container
 * @param {boolean}           options.logRetention       enable log retention for this container
 * @param callback
 */
exports.updateCdnContainer = function (container, options, callback) {
  var self = this,
    containerName = container instanceof self.models.Container ? container.name : container;

  var cdnOpts = {
    method: 'POST',
    container: containerName,
    serviceType: this.cdnServiceType,
    headers: {}
  };

  if (options.ttl) {
    cdnOpts.headers['x-ttl'] = options.ttl;
  }

  if (typeof options.enabled === 'boolean') {
    cdnOpts.headers['x-cdn-enabled'] = options.enabled;
  }

  if (typeof options.logRetention === 'boolean') {
    cdnOpts.headers['x-log-retention'] = options.logRetention;
  }

  self._request(cdnOpts, function (err) {
    if (err) {
      return callback(err);
    }

    self.getContainer(containerName, function (err, container) {
      return err
        ? callback(err)
        : callback(err, container);
    });
  });
};

/**
 * client._getCdnContainerDetails
 *
 * @description Convenience function for getting CDN container details
 */
exports._getCdnContainerDetails = function(container, callback) {
  var containerName = container instanceof this.models.Container ? container.name : container,
    self = this;

  this._request({
    method: 'HEAD',
    container: containerName,
    serviceType: this.cdnServiceType
  }, function (err, body, res) {
    if (err && !(err.statusCode === 404)) {
      return callback(err);
    }
    else if (err) {
      return callback(null, {}); // return empty object
    }

    container = {
      name: containerName,
      count: parseInt(res.headers['x-container-object-count'], 10),
      bytes: parseInt(res.headers['x-container-bytes-used'], 10)
    };

    container.cdnUri = res.headers['x-cdn-uri'];
    container.cdnSslUri = res.headers['x-cdn-ssl-uri'];
    container.cdnEnabled = res.headers['x-cdn-enabled'] == 'True';
    container.cdnStreamingUri = res.headers['x-cdn-streaming-uri'];
    container.cdniOSUri = res.headers['x-cdn-ios-uri'];
    container.ttl = parseInt(res.headers['x-ttl'], 10);
    container.logRetention = res.headers['x-log-retention'] == 'True';

    container.metadata = self.deserializeMetadata(self.CONTAINER_META_PREFIX, res.headers);

    callback(null, container);
  });
};

/**
 * client.setTemporaryUrlKey
 *
 * @description set a temporaryUrl key on the current account
 *
 * @param {String}     key     the secret key to be used in hmac signing temporary urls
 * @param callback
 */
exports.setTemporaryUrlKey = function(key, callback) {
  this._request({
    method: 'POST',
    headers: {
      'X-Account-Meta-Temp-Url-Key': key
    }
  }, function (err) {
    callback(err)
  });
};

/**
 * client.generateTempUrl
 *
 * @description create a temporary url for GET/PUT to a cloud files container
 *
 * @param {String|object}     container     the container or container name for the url
 * @param {String|object}     file          the file or fileName for the url
 * @param {String}            method        either GET or PUT
 * @param {Number}            time          expiry for the url in seconds (from now)
 * @param {String}            key           the secret key to be used for signing the url
 * @param callback
 */
exports.generateTempUrl = function(container, file, method, time, key, callback) {
  var containerName = container instanceof this.models.Container ? container.name : container,
    fileName = file instanceof this.models.File ? file.name : file,
    time = typeof time === 'number' ? time : parseInt(time),
    self = this,
    split = '/v1';

  // We have to be authed to make sure we have the service catalog
  // this is required to validate the service url

  if (!this._isAuthorized()) {
    this.auth(function(err) {
      if (err) {
        callback(err);
        return;
      }

      createUrl();
    });

    return;
  }

  createUrl();

  function createUrl() {
    // construct our hmac signature
    var expiry = parseInt(new Date().getTime() / 1000) + time,
      url = self._getUrl({
        container: containerName,
        path: fileName
      }),
      hmac_body = method.toUpperCase() + '\n' + expiry + '\n' + split + url.split(split)[1];

    var hash = crypto.createHmac('sha1', key).update(hmac_body).digest('hex');

    callback(null, url + "?temp_url_sig=" + hash + "&temp_url_expires=" + expiry);
  }
};