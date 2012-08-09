var Broker = function (app_key, options) {
    this.options = options || {};
    this.key = app_key;
    this.auth_endpoint = "auth";
    this.channels = {};
}

Broker.prototype.connect = function () {
    var sockjs_url = '/subscribe';
    this.ws = new SockJS(sockjs_url);
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
        var evt = new Event(data.event);
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

Broker.prototype.on = function (eventType, listener) {
    this.ws.addEventListener(eventType, listener);
};

Broker.prototype.off = function (eventType, listener) {
    this.ws.removeEventListener(eventType, listener);
};

Broker.prototype.disconnect = function () {
    
};

Broker.prototype.subscribe = function (channel_name) {
    var self = this;
    if (this.channels[channel_name]) return this;

    if (!channel_name.match(/^(private.[a-z]*)/)) {
        this.channels[escape(channel_name)] =
            new Channel(this.ws, escape(channel_name));
        return this;
    }

    this.authorize(channel_name, function (privChannel) {
        self.channels[escape(channel_name)] =
            new Channel(self.ws, escape(privChannel), escape(channel_name));
    });

    return this; // chainable
};

Broker.prototype.authorize = function (channel_name, callback) {
    $.get(this.auth_endpoint, {channel: channel_name}, callback);
};

Broker.prototype.unsubscribe = function (channel_name) {
    if (!this.channels[escape(channel_name)]) return;
    delete this.channels[escape(channel_name)];
    sendWsMessage(this.ws, "client-unsubscribe", name);
};

var Channel = function(ws, name, publicName) {
    this.name = publicName || name;
    this.isPrivate = (publicName !== undefined);
    this.privateName = this.isPrivate? name : "";

    this.ws = ws;
    var self = this;
    var onopen = function() {
        sendWsMessage(ws, "client-subscribe", name);

        ws.addEventListener('message', function (e) {
            var data = JSON.parse(e.data);
            if (!data.event || !data.channel) return;
            var channel = self.privateName || self.name;
            if (data.channel !== channel) return;
            var evt = new Event(channel+'.'+data.event);
            evt.data = data.payload;
            ws.dispatchEvent(evt);
        });

        if (!self.isPrivate) return;
        self.on("channel-change", function () {

        });
    };

    if (ws.readyState > 0) {
        setTimeout(onopen, 0);
    } else {
        ws.addEventListener('open', onopen);
    }
};

Channel.prototype.on = function(eventType, listener) {
    var channel = this.privateName || this.name;
    sendWsMessage(this.ws, "client-bind-event", channel, eventType);
    this.ws.addEventListener(channel+'.'+eventType, listener);
};

Channel.prototype.off = function(eventType, listener) {
    var channel = this.privateName || this.name;
    sendWsMessage(this.ws, "client-unbind-event", channel, eventType);
    this.ws.removeEventListener(channel+'.'+eventType, listener);
};

Channel.prototype.trigger = function (event_name, payload) {
    // Requirement: Client cannot publish to public channel
    if (!this.isPrivate) return false;
    // Requirement: Event has to have client- prefix.
    if (!event_name.match(/^(client-[a-z0-9]*)/)) return false;
    var channel = this.privateName || this.name;
    sendWsMessage(this.ws, event_name, channel, payload);
    return true;
};

var sendWsMessage = function (ws, event_name, channel, payload) {
    var subJSON = {event:event_name,channel:channel,payload:payload};
    ws.send(JSON.stringify(subJSON));
}