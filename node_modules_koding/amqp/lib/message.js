'use strict';
var events = require('events'),
    util = require('util'),
    fs = require('fs'),
    protocol,
    definitions = require('./definitions');


// Properties:
// - routingKey
// - size
// - deliveryTag
//
// - contentType (default 'application/octet-stream')
// - contentEncoding
// - headers
// - deliveryMode
// - priority (0-9)
// - correlationId
// - replyTo
// - experation
// - messageId
// - timestamp
// - userId
// - appId
// - clusterId
var Message = module.exports = function Message (queue, args) {
  var msgProperties = definitions.classes[60].fields;

  events.EventEmitter.call(this);

  this.queue = queue;

  this.deliveryTag = args.deliveryTag;
  this.redelivered = args.redelivered;
  this.exchange    = args.exchange;
  this.routingKey  = args.routingKey;
  this.consumerTag = args.consumerTag;

  for (var i=0, l=msgProperties.length; i<l; i++) {
      if (args[msgProperties[i].name]) {
          this[msgProperties[i].name] = args[msgProperties[i].name];
      }
  }
};
util.inherits(Message, events.EventEmitter);


// Acknowledge receipt of message.
// Set first arg to 'true' to acknowledge this and all previous messages
// received on this queue.
Message.prototype.acknowledge = function (all) {
  this.queue.connection._sendMethod(this.queue.channel, definitions.methods.basicAck,
      { reserved1: 0
      , deliveryTag: this.deliveryTag
      , multiple: all ? true : false
      });
};

// Reject an incoming message.
// Set first arg to 'true' to requeue the message.
Message.prototype.reject = function (requeue){
  this.queue.connection._sendMethod(this.queue.channel, definitions.methods.basicReject,
      { deliveryTag: this.deliveryTag
      , requeue: requeue ? true : false
      });
};




