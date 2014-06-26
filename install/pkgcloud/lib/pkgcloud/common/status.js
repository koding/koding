/*
 * status.js: Standardized statuses for different services
 *
 * (C) 2011-2012 Nodejitsu Inc.
 *
 */

exports.compute = {
  error: 'ERROR',
  provisioning: 'PROVISIONING',
  reboot: 'REBOOT',
  running: 'RUNNING',
  stopped: 'STOPPED',
  terminated: 'TERMINATED',
  unknown: 'UNKNOWN',
  updating: 'UPDATING'
};