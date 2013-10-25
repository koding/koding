'use strict';
var util = require('util');
var fs = require('fs');
var _ = require('lodash');
var Channel = require('./channel');
var Exchange = require('./exchange');
var Message = require('./message');
var debug = require('./debug');
var definitions = require('./definitions');
var methods = definitions.methods;
var classes = definitions.classes;
    

var Queue = module.exports = function Queue (connection, channel, name, options, callback) {
  Channel.call(this, connection, channel);

  var self = this;
  this.name = name;
  this._bindings = {};
  this.consumerTagListeners = {};
  this.consumerTagOptions = {};
  
  // route messages to subscribers based on consumerTag
  this.on('rawMessage', function(message) {
    if (message.consumerTag && self.consumerTagListeners[message.consumerTag]) {
      self.consumerTagListeners[message.consumerTag](message);
    }
  });
  
  this.options = { autoDelete: true, closeChannelOnUnsubscribe: false };
  _.extend(this.options, options || {});

  this._openCallback = callback;
};
util.inherits(Queue, Channel);

Queue.prototype.subscribeRaw = function (options, messageListener) {
  var self = this;

  // multiple method signatures
  if (typeof options === "function") {
    messageListener = options;
    options = {};
  }

  var consumerTag = 'node-amqp-' + process.pid + '-' + Math.random();
  this.consumerTagListeners[consumerTag] = messageListener;

  options = options || {};
  options['state'] = 'opening';
  this.consumerTagOptions[consumerTag] = options;
  if (options.prefetchCount !== undefined) {
    self.connection._sendMethod(self.channel, methods.basicQos,
        { reserved1: 0
        , prefetchSize: 0
        , prefetchCount: options.prefetchCount
        , global: false
        });
  }

  return this._taskPush(methods.basicConsumeOk, function () {
    self.connection._sendMethod(self.channel, methods.basicConsume,
        { reserved1: 0
        , queue: self.name
        , consumerTag: consumerTag
        , noLocal: !!options.noLocal
        , noAck: !!options.noAck
        , exclusive: !!options.exclusive
        , noWait: false
        , "arguments": {}
        });
    self.consumerTagOptions[consumerTag]['state'] = 'open';
  });
};

Queue.prototype.unsubscribe = function(consumerTag) {
  var self = this;
  return this._taskPush(methods.basicCancelOk, function () {
    self.connection._sendMethod(self.channel, methods.basicCancel,
                                { reserved1: 0,
                                  consumerTag: consumerTag,
                                  noWait: false });
  })
  .addCallback(function () {
    if(self.options.closeChannelOnUnsubscribe){
      self.close();
    }
    delete self.consumerTagListeners[consumerTag];
    delete self.consumerTagOptions[consumerTag];
  });
};

Queue.prototype.subscribe = function (options, messageListener) {
  var self = this;

  // Optional options
  if (typeof options === "function"){
    messageListener = options;
    options = {};
  }

  options = _.defaults(options || {}, { 
    ack: false,
    prefetchCount: 1,
    routingKeyInPayload: self.connection.options.routingKeyInPayload,
    deliveryTagInPayload: self.connection.options.deliveryTagInPayload 
  });

  // basic consume
  var rawOptions = {
      noAck: !options.ack,
      exclusive: options.exclusive
  };
  if (options.ack) {
    rawOptions['prefetchCount'] = options.prefetchCount;
  }
  return this.subscribeRaw(rawOptions, function (m) {
    var contentType = m.contentType;
    
    if (contentType == null && m.headers && m.headers.properties) {
       contentType = m.headers.properties.content_type;
    }
    
    var isJSON = (contentType == 'text/json') || (contentType == 'application/json');

    var buffer;

    if (isJSON) {
      buffer = "";
    } else {
      buffer = new Buffer(m.size);
      buffer.used = 0;
    }

    self._lastMessage = m;

    m.addListener('data', function (d) {
      if (isJSON) {
        buffer += d.toString();
      } else {
        d.copy(buffer, buffer.used);
        buffer.used += d.length;
      }
    });

    m.addListener('end', function () {
      var json, deliveryInfo = {}, msgProperties = classes[60].fields, i, l;
      if (isJSON) {
        try {
          json = JSON.parse(buffer);
        } catch (e) {
          json = null;
          deliveryInfo.parseError = e;
          deliveryInfo.rawData = buffer;
        }
      } else {
        json = { data: buffer, contentType: m.contentType };
      }
      for (i = 0, l = msgProperties.length; i<l; i++) {
        if (m[msgProperties[i].name]) {
          deliveryInfo[msgProperties[i].name] = m[msgProperties[i].name];
        }
      }
      deliveryInfo.queue = m.queue ? m.queue.name : null;
      deliveryInfo.deliveryTag = m.deliveryTag;
      deliveryInfo.redelivered = m.redelivered;
      deliveryInfo.exchange = m.exchange;
      deliveryInfo.routingKey = m.routingKey;
      deliveryInfo.consumerTag = m.consumerTag;
      if(options.routingKeyInPayload) json._routingKey = m.routingKey;
      if(options.deliveryTagInPayload) json._deliveryTag = m.deliveryTag;

      var headers = {};
      for (i in this.headers) {
        if(this.headers.hasOwnProperty(i)) {
          if(this.headers[i] instanceof Buffer)
            headers[i] = this.headers[i].toString();
          else
            headers[i] = this.headers[i];
        }
      }
      if (messageListener) messageListener(json, headers, deliveryInfo, m);
      self.emit('message', json, headers, deliveryInfo, m);
    });
  });
};
Queue.prototype.subscribeJSON = Queue.prototype.subscribe;

/* Acknowledges the last message */
Queue.prototype.shift = function (reject, requeue) {
  if (this._lastMessage) {
    if (reject) {
      this._lastMessage.reject(requeue ? true : false);
    } else {
      this._lastMessage.acknowledge();
    } 
  }
};


Queue.prototype.bind = function (exchange, routingKey, callback) {
  var self = this;

  // The first argument, exchange is optional.
  // If not supplied the connection will use the 'amq.topic'
  // exchange.
  if (routingKey === undefined || _.isFunction(routingKey)) {
    callback = routingKey;
    routingKey = exchange;
    exchange = 'amq.topic';
  }

  if(_.isFunction(callback)) this._bindCallback = callback;

  var exchangeName = exchange instanceof Exchange ? exchange.name : exchange;

  if(exchangeName in self.connection.exchanges) {
    this.exchange = self.connection.exchanges[exchangeName];
    this.exchange.binds++;
  }

  // Record this binding so we can restore it upon reconnect.
  if (!this._bindings[exchangeName]) {
      this._bindings[exchangeName] = {};
  }
  if (!this._bindings[exchangeName][routingKey]) {
      this._bindings[exchangeName][routingKey] = 0;
  }
  this._bindings[exchangeName][routingKey]++;

  self.connection._sendMethod(self.channel, methods.queueBind,
      { reserved1: 0
      , queue: self.name
      , exchange: exchangeName
      , routingKey: routingKey
      , noWait: false
      , "arguments": {}
      });

};

Queue.prototype.unbind = function (exchange, routingKey) {
  var self = this;

  // The first argument, exchange is optional.
  // If not supplied the connection will use the default 'amq.topic'
  // exchange.
  if (routingKey === undefined) {
    routingKey = exchange;
    exchange = 'amq.topic';
  }
  var exchangeName = exchange instanceof Exchange ? exchange.name : exchange;

  // Decrement binding count.
  this._bindings[exchangeName][routingKey]--;
  if (!this._bindings[exchangeName][routingKey]) {
    delete this._bindings[exchangeName][routingKey];
  }

  // If there are no more bindings to this exchange, delete the key for the exchange.
  if (!_.keys(this._bindings[exchangeName]).length){
    delete this._bindings[exchangeName];
  }

  return this._taskPush(methods.queueUnbindOk, function () {
    self.connection._sendMethod(self.channel, methods.queueUnbind,
        { reserved1: 0
        , queue: self.name
        , exchange: exchangeName
        , routingKey: routingKey
        , noWait: false
        , "arguments": {}
        });
  });
};

Queue.prototype.bind_headers = function (/* [exchange,] matchingPairs */) {
  var self = this;

  // The first argument, exchange is optional.
  // If not supplied the connection will use the default 'amq.headers'
  // exchange.

  var exchange, matchingPairs;

  if (arguments.length == 2) {
    exchange = arguments[0];
    matchingPairs = arguments[1];
  } else {
    exchange = 'amq.headers';
    matchingPairs = arguments[0];
  }


  return this._taskPush(methods.queueBindOk, function () {
    var exchangeName = exchange instanceof Exchange ? exchange.name : exchange;
    self.connection._sendMethod(self.channel, methods.queueBind,
        { reserved1: 0
        , queue: self.name
        , exchange: exchangeName
        , routingKey: ''
        , noWait: false
        , "arguments": matchingPairs
        });
  });
};


Queue.prototype.destroy = function (options) {
  var self = this;

  options = options || {};
  return this._taskPush(methods.queueDeleteOk, function () {
    self.connection.queueClosed(self.name);
    if('exchange' in self) {
      self.exchange.binds--;
      self.exchange.cleanup();
    }
    self.connection._sendMethod(self.channel, methods.queueDelete,
        { reserved1: 0
        , queue: self.name
        , ifUnused: options.ifUnused ? true : false
        , ifEmpty: options.ifEmpty ? true : false
        , noWait: false
        , "arguments": {}
    });
  });
};

Queue.prototype.purge = function() {
  var self = this;
  return this._taskPush(methods.queuePurgeOk, function () {
    self.connection._sendMethod(self.channel, methods.queuePurge,
                                 { reserved1 : 0,
                                 queue: self.name,
                                 noWait: false});
  });
};


Queue.prototype._onMethod = function (channel, method, args) {
  var self = this;
  this.emit(method.name, args);
  if (this._handleTaskReply.apply(this, arguments)) return;

  switch (method) {
    case methods.channelOpenOk:
      if (this.options.noDeclare) {
        this.state = 'open';

        if (this._openCallback) {
         this._openCallback(this);
         this._openCallback = null;
        }

        this.emit('open');
      } else { 
        this.connection._sendMethod(channel, methods.queueDeclare,
            { reserved1: 0
            , queue: this.name
            , passive: !!this.options.passive
            , durable: !!this.options.durable
            , exclusive: !!this.options.exclusive
            , autoDelete: !!this.options.autoDelete
            , noWait: false
            , "arguments": this.options.arguments || {}
            });
        this.state = "declare queue";
      }
      break;

    case methods.queueDeclareOk:
      this.state = 'open';
      this.name = args.queue;
      this.connection.queues[this.name] = this;

      // Rebind to previously bound exchanges, if present.
      // Important this is called *before* openCallback, otherwise bindings will happen twice.
      // Run test-purge to make sure you got this right
      _.each(this._bindings, function(exchange, exchangeName){
        _.each(exchange, function(count, routingKey){
          self.bind(exchangeName, routingKey);
        });
      });

      // Call opening callback (passed in function)
      // FIXME use eventemitter - maybe we call a namespaced event here
      if (this._openCallback) {
        this._openCallback(this, args.messageCount, args.consumerCount);
        this._openCallback = null;
      }

      // TODO this is legacy interface, remove me
      this.emit('open', args.queue, args.messageCount, args.consumerCount);
      
      // If this is a reconnect, we must re-subscribe our queue listeners.
      var consumerTags = Object.keys(this.consumerTagListeners);
      for (var index in consumerTags) {
        if (consumerTags.hasOwnProperty(index)) {
          if (this.consumerTagOptions[consumerTags[index]]['state'] === 'closed') {
            this.subscribeRaw(this.consumerTagOptions[consumerTags[index]], this.consumerTagListeners[consumerTags[index]]);
            // Having called subscribeRaw, we are now a new consumer with a new consumerTag.
            delete this.consumerTagListeners[consumerTags[index]];
            delete this.consumerTagOptions[consumerTags[index]];
          }
        }
      }
      break;

    case methods.basicConsumeOk:
      debug('basicConsumeOk', util.inspect(args, null));
      break;

    case methods.queueBindOk:
      if (this._bindCallback) {
        // setting this._bindCallback to null before calling the callback allows for a subsequent bind within the callback
        // FIXME use eventemitter
        var cb = this._bindCallback;
        this._bindCallback = null;
        cb(this);
      }
      break;

    case methods.basicQosOk:
      break;

    case methods.confirmSelectOk:
      this._sequence = 1;
      this.confirm = true;
      break;

    case methods.channelClose:
      this.state = "closed";
      this.closeOK();
      this.connection.queueClosed(this.name);
      var e = new Error(args.replyText);
      e.code = args.replyCode;
      this.emit('error', e);
      this.emit('close');
      break;
    
    case methods.channelCloseOk:
      this.connection.queueClosed(this.name);
      this.emit('close');
      break;
    
    case methods.basicDeliver:
      this.currentMessage = new Message(this, args);
      break;

    case methods.queueDeleteOk:
      break;

    default:
      throw new Error("Uncaught method '" + method.name + "' with args " +
          JSON.stringify(args) + "; tasks = " + JSON.stringify(this._tasks));
  }

  this._tasksFlush();
};


Queue.prototype._onContentHeader = function (channel, classInfo, weight, properties, size) {
  _.extend(this.currentMessage, properties);
  this.currentMessage.read = 0;
  this.currentMessage.size = size;

  this.emit('rawMessage', this.currentMessage);
  if (size === 0) {
    // If the message has no body, directly emit 'end'
    this.currentMessage.emit('end');
  }
};

Queue.prototype._onContent = function (channel, data) {
  this.currentMessage.read += data.length;
  this.currentMessage.emit('data', data);
  if (this.currentMessage.read == this.currentMessage.size) {
    this.currentMessage.emit('end');
  }
};

Queue.prototype.flow = function(active) {
    var self = this;
    return this._taskPush(methods.channelFlowOk, function () {
      self.connection._sendMethod(self.channel, methods.channelFlow, {'active': active });
    });
};
