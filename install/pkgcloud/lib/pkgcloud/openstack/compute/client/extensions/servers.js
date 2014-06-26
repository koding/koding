/*
 * servers.js: OpenStack Servers Extension
 *
 * (C) 2014
 *      Alvaro M. Reol
 * MIT LICENSE
 *
 */

var Server = require('../../server').Server,
    urlJoin = require('url-join');

var _extension = 'servers';

/**
 * client.startServer
 *
 * @description Starts a stopped server and changes its status to ACTIVE.
 *
 * @param {String|Object}   server          The server ID or server to start
 * @param {function}        callback
 * @returns {*}
 */
exports.startServer = function (server, callback) {
    return this._doServerAction(server,
        {'os-start': null},
        function (err) {
            return callback(err);
    });
};

/**
 * client.stopServer
 *
 * @description Stops a running server and changes its status to STOPPED.
 *
 * @param {String|Object}   server          The server ID or server to stop
 * @param {function}        callback
 * @returns {*}
 */
exports.stopServer = function (server, callback) {
    return this._doServerAction(server,
        {'os-stop': null},
        function (err) {
            return callback(err);
        });
};

