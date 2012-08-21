var Broker = function (app_key, options) {
    this.options = options || {};
    //this.sockURL = this.options.sockURL || 'http://web0.beta.system.aws.koding.com:8008/subscribe';
    this.sockURL = this.options.sockURL || 'http://'+window.location.hostname+':8008/subscribe';
    this.key = app_key;
    this.channels = {};
    this.connect();
}

Broker.channel_auth_endpoint = "auth";

Broker.prototype.connect = function () {
    this.ws = new SockJS(this.sockURL);
    var self = this;

    // Initial set up to acquire socket_id
    var initialListener = function (e) {
        var data = JSON.parse(e.data);
        if (!data.socket_id) return;
        self.socket_id = data.socket_id;
        setTimeout(function() {
            self.ws.removeEventListener('message', initialListener);
        }, 0);
    }
    this.ws.addEventListener('message', initialListener);

    // Dispatch global events on receiving message
    this.ws.addEventListener('message', function (e) {
        var data = JSON.parse(e.data);
        if (!data.event) return;
        var evt = {};
        evt.type = data.event;        
        evt.data = data.payload;
        self.ws.dispatchEvent(evt);
    });

    this.ws.addEventListener('open', function() {
        self.on("channel-change", function (e) {
            var channel = e.data;
            self.unsubscribe(channel);
            self.subscribe(channel);
        })
    })

    return this; // chainable
};

Broker.prototype.channel = function (name) {
    return this.channels[name];
};

Broker.prototype.on = Broker.prototype.bind = function (eventType, listener, ctx) {
    var self = this;
    this.ws.addEventListener(eventType, function (event) {
        listener.call(ctx || self, event.data);
    });
};

Broker.prototype.off = Broker.prototype.unbind = function (eventType, listener) {
    this.ws.removeEventListener(eventType, listener);
};

Broker.prototype.disconnect = function () {
    
};

Broker.prototype.subscribe = function (channelName) {
    var self = this;
    if (this.channels[channelName]) return this;
    var channel = new Channel(this.ws, escape(channelName));
    this.channels[escape(channelName)] = channel;

    channel.isPrivate = /^(private-[\w-.]*)/.test(channelName);

    if (!channel.isPrivate) {
        channel.state.emit('authorized');
        return channel;
    }

    this.authorize(channelName, function (privName) {
        channel.privateName = privName;
        channel.name = channelName;
        channel.state.emit('authorized');
    })
    return channel;
};

Broker.prototype.authorize = function (channelName, callback) {
    $.get(Broker.channel_auth_endpoint, {channel: channelName}, callback);
};

Broker.prototype.unsubscribe = function (channel) {
    if (typeof channel === "string")
        channel = this.channels[escape(channel)];
    if (!channel) return;
    delete channel;
    sendWsMessage(this.ws, "client-unsubscribe", channel);
};

var Channel = function(ws, name) {     
    this.name = name;
    this.state = new EventEmitter;
    this.ws = ws;
    var self = this;
    var onopen = function() {
        if (ws.readyState > 0) {
            sendWsMessage(ws, "client-subscribe", self.privateName || self.name);

            ws.addEventListener('message', function (e) {
                var data = JSON.parse(e.data);
                if (!data.event || !data.channel) return;
                var channel = self.privateName || self.name;
                if (data.channel !== channel) return;
                var evt = {};
                evt.type = channel+'.'+data.event;
                if (data.payload) {
                  data.payload = JSON.parse(data.payload);
                }
                evt.data = data.payload;
                ws.dispatchEvent(evt);
            });
        }
        else {
            ws.addEventListener('open', function () {
                onopen();
            });
        }
    };

    self.state.on('authorized', onopen);
};

Channel.prototype.on = Channel.prototype.bind = function(eventType, listener, ctx) {
    var self = this;
    var brokerListener = function (eventObj) {
        listener.call(ctx || self, eventObj.data);
    };

    if (this.ws.readyState > 0) {
        if (!this.isPrivate || this.privateName) {
            var channel = this.privateName || this.name;
            sendWsMessage(this.ws, "client-bind-event", channel, eventType);
            this.ws.addEventListener(channel+'.'+eventType, brokerListener);
        } else {
            this.state.on('authorized', this.on.bind(this, eventType, listener));
        }
    } else {
        this.ws.addEventListener('open', this.on.bind(this, eventType, listener));
    }
};

Channel.prototype.off = Channel.prototype.unbind = function(eventType, listener) {
    var channel = this.privateName || this.name;
    sendWsMessage(this.ws, "client-unbind-event", channel, eventType);
    this.ws.removeEventListener(channel+'.'+eventType, listener);
};

Channel.prototype.emit = Channel.prototype.trigger = function (eventType, payload) {
    // Requirement: Client cannot publish to public channel
    if (!this.isPrivate) return false;
    // Requirement: Event has to have client- prefix.
    if (!eventType.match(/^(client-[a-z0-9]*)/)) return false;
    var channel = this.privateName || this.name;
    sendWsMessage(this.ws, eventType, channel, payload);
    return true;
};

var sendWsMessage = function (ws, event_name, channel, payload) {
    var subJSON = {event:event_name,channel:channel,payload:payload};
    ws.send(JSON.stringify(subJSON));
}


// MICRO EVENT EMIITTER

var EventEmitter,
  __slice = [].slice,
  __hasProp = {}.hasOwnProperty;

EventEmitter = (function() {
  var createId, defineProperty, idKey;

  idKey = 'ಠ_ಠ';

  EventEmitter.listeners = {};

  EventEmitter.targets = {};

  EventEmitter.off = function(listenerId) {
    /*
        Note: @off, but no symmetrical "@on".  This is by design.
          One shouldn't add event listeners directly.  These static
          collections are maintained so that the listeners may be
          garbage collected and removed from the emitter's record.
          To that end, @off provides a handy interface.
    */
    delete this.listeners[listenerId];
    delete this.targets[listenerId];
    return this;
  };

  defineProperty = Object.defineProperty || function(obj, prop, _arg) {
    var value;
    value = _arg.value;
    return obj[prop] = value;
  };

  createId = (function() {
    var counter;
    counter = 0;
    return function() {
      return counter++;
    };
  })();

  function EventEmitter(options) {
    if (options == null) {
      options = {};
    }
    defineProperty(this, idKey, {
      value: "" + (Math.round(Math.random() * 1e9))
    });
    defineProperty(this, '_events', {
      value: {},
      writable: true
    });
  }

  EventEmitter.prototype.on = function(evt, listener) {
    var lid, listeners, _base;
    listeners = (_base = this._events)[evt] || (_base[evt] = {});
    if (this[idKey] in listener) {
      lid = listener[this[idKey]];
    } else {
      lid = createId();
      defineProperty(listener, this[idKey], {
        value: lid
      });
    }
    EventEmitter.listeners[lid] = listeners[lid] = listener;
    EventEmitter.targets[lid] = this;
    return lid;
  };

  EventEmitter.prototype.when = function() {};

  EventEmitter.prototype.off = function(evt, listener) {
    var listenerId, listeners;
    switch (arguments.length) {
      case 0:
        this._events = {};
        break;
      case 1:
        this._events[evt] = {};
        break;
      default:
        listeners = this._events[evt];
        listenerId = listener[this[idKey]];
        delete listeners[listenerId];
        EventEmitter.off(listenerId);
    }
    return this;
  };

  EventEmitter.prototype.emit = function() {
    var evt, id, listener, listeners, rest;
    evt = arguments[0], rest = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    listeners = this._events[evt];
    for (id in listeners) {
      if (!__hasProp.call(listeners, id)) continue;
      listener = listeners[id];
      listener.call.apply(listener, [this].concat(__slice.call(rest)));
    }
    return this;
  };

  return EventEmitter;

})();

if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
  define(function() {
    return EventEmitter;
  });
} else {
  this['EventEmitter'] = EventEmitter;
}