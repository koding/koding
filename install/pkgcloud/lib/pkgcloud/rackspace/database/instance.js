/*
 * instances.js: Rackspace Cloud Database Instance
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    model = require('../../core/base/model'),
    computeStatus = require('../../common/status').compute;

var Instance = exports.Instance = function Instance(client, details) {
  model.Model.call(this, client, details);
};

utile.inherits(Instance, model.Model);

Instance.prototype.refresh = function (callback) {
  this.client.getInstance(this, callback);
};

Instance.prototype.STATUS = computeStatus;

Instance.prototype._setProperties = function (details) {
  this.id = details.id;
  this.name = details.name;
  this.links = details.links;

  // Fix for name in rackspace
  details.state = (details.status) ? details.status : details.state;

  if (details.state) {
    switch (details.state.toUpperCase()) {
      case 'PROVISIONING':
      case 'BUILD':
      case 'REBOOT':
      case 'RESIZE':
        this.status = this.STATUS.provisioning;
        break;
      case 'RUNNING':
      case 'ACTIVE': // Change for keep consistency
        this.status = this.STATUS.running;
        break;
      case 'STOPPING':
      case 'STOPPED':
      case 'SHUTDOWN':
        this.status = this.STATUS.stopped;
        break;
      case 'FAILED':
        this.status = this.STATUS.error;
        break;
      default:
        this.status = this.STATUS.unknown;
        break;
    }
  }

  // Seems Rackspace not will provide this fields so I comment it.
  //this.created  = details.created  || this.created;
  //this.updated  = details.updated  || this.updated;
  this.flavor   = details.flavor   || {};
  this.hostname = details.hostname || this.hostname;
  this.volume   = details.volume   || this.volume;
  this.original = this.rackspace = details;
};