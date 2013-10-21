'use strict';
var events = require('events');
var util = require('util');
var fs = require('fs');
var Promise = require('./promise').Promise;
var definitions = require('./definitions');
var methods = definitions.methods;
  

// This class is not exposed to the user. Queue and Exchange are subclasses
// of Channel. This just provides a task queue.
var Channel = module.exports = function Channel (connection, channel) {
  events.EventEmitter.call(this);
  // Unlimited listeners. Helps when e.g. publishing high-volume messages, 10 is far too low.
  this.setMaxListeners(0); 

  this.channel = channel;
  this.connection = connection;
  this._tasks = [];

  this.reconnect();
};
util.inherits(Channel, events.EventEmitter);

Channel.prototype.closeOK = function() {
  this.connection._sendMethod(this.channel, methods.channelCloseOk, {reserved1: ""});
};

Channel.prototype.reconnect = function () {
  this.connection._sendMethod(this.channel, methods.channelOpen, {reserved1: ""});
};

Channel.prototype._taskPush = function (reply, cb) {
  var promise = new Promise();
  this._tasks.push({ 
    promise: promise,
    reply: reply,
    sent: false,
    cb: cb
  });
  this._tasksFlush();
  return promise;
};

Channel.prototype._tasksFlush = function () {
  if (this.state != 'open') return;

  for (var i = 0; i < this._tasks.length; i++) {
    var task = this._tasks[i];
    if (task.sent) continue;
    task.cb();
    task.sent = true;
    if (!task.reply) {
      // if we don't expect a reply, just delete it now
      this._tasks.splice(i, 1);
      i = i-1;
    }
  }
};

Channel.prototype._handleTaskReply = function (channel, method, args) {
  var task, i;

  for (i = 0; i < this._tasks.length; i++) {
    if (this._tasks[i].reply == method) {
      task = this._tasks[i];
      this._tasks.splice(i, 1);
      task.promise.emitSuccess(args);
      this._tasksFlush();
      return true;
    }
  }

  return false;
};

Channel.prototype._onChannelMethod = function(channel, method, args) {
  switch (method) {
    case methods.channelCloseOk:
        delete this.connection.channels[this.channel];
        this.state = 'closed';
    default:
        this._onMethod(channel, method, args);
  }
};

Channel.prototype.close = function() { 
  this.state = 'closing';
    this.connection._sendMethod(this.channel, methods.channelClose,
                                {'replyText': 'Goodbye from node',
                                 'replyCode': 200,
                                 'classId': 0,
                                 'methodId': 0});
};
