var events = require('events'),
    util = require('util'),
    net = require('net'),
    protocol,
    jspack = require('./jspack').jspack,
    Buffer = require('buffer').Buffer,
    Promise = require('./promise').Promise,
    URL = require('url'),
    AMQPTypes = require('./constants').AMQPTypes,
    Indicators = require('./constants').Indicators,
    FrameType = require('./constants').FrameType;
    
function mixin () {
  // copy reference to target object
  var target = arguments[0] || {}, i = 1, length = arguments.length, deep = false, source;

  // Handle a deep copy situation
  if ( typeof target === "boolean" ) {
    deep = target;
    target = arguments[1] || {};
    // skip the boolean and the target
    i = 2;
  }

  // Handle case when target is a string or something (possible in deep copy)
  if ( typeof target !== "object" && !(typeof target === 'function') )
    target = {};

  // mixin process itself if only one argument is passed
  if ( length == i ) {
    target = GLOBAL;
    --i;
  }

  for ( ; i < length; i++ ) {
    // Only deal with non-null/undefined values
    if ( (source = arguments[i]) != null ) {
      // Extend the base object
      Object.getOwnPropertyNames(source).forEach(function(k){
        var d = Object.getOwnPropertyDescriptor(source, k) || {value: source[k]};
        if (d.get) {
          target.__defineGetter__(k, d.get);
          if (d.set) {
            target.__defineSetter__(k, d.set);
          }
        }
        else {
          // Prevent never-ending loop
          if (target === d.value) {
            return;
          }

          if (deep && d.value && typeof d.value === "object") {
            target[k] = mixin(deep,
              // Never move original objects, clone them
              source[k] || (d.value.length != null ? [] : {})
            , d.value);
          }
          else {
            target[k] = d.value;
          }
        }
      });
    }
  }
  // Return the modified object
  return target;
}


var debugLevel = process.env['NODE_DEBUG_AMQP'] ? 1 : 0;
function debug (x) {
  if (debugLevel > 0) console.error(x + '\n');
}


// a look up table for methods recieved
// indexed on class id, method id
var methodTable = {};

// methods keyed on their name
var methods = {};

// classes keyed on their index
var classes = {};

(function () { // anon scope for init
  //debug("initializing amqp methods...");
  protocol = require('./amqp-definitions-0-9-1');

  for (var i = 0; i < protocol.classes.length; i++) {
    var classInfo = protocol.classes[i];
    classes[classInfo.index] = classInfo;
    for (var j = 0; j < classInfo.methods.length; j++) {
      var methodInfo = classInfo.methods[j];
      
      var name = classInfo.name
        + methodInfo.name[0].toUpperCase()
        + methodInfo.name.slice(1);
      //debug(name);
      
      var method = { name: name
                     , fields: methodInfo.fields
                     , methodIndex: methodInfo.index
                     , classIndex: classInfo.index
                   };
      
      if (!methodTable[classInfo.index]) methodTable[classInfo.index] = {};
      methodTable[classInfo.index][methodInfo.index] = method;
      methods[name] = method;
    }
  }
})(); // end anon scope

// parser

var maxFrameBuffer = 131072; // 128k, same as rabbitmq (which was
                             // copying qpid)
var emptyFrameSize = 8;      // This is from the javaclient
var maxFrameSize = maxFrameBuffer - emptyFrameSize;
// An interruptible AMQP parser.
//
// type is either 'server' or 'client'
// version is '0-9-1'.
//
// Instances of this class have several callbacks
// - onMethod(channel, method, args);
// - onHeartBeat()
// - onContent(channel, buffer);
// - onContentHeader(channel, class, weight, properties, size);
//
// This class does not subclass EventEmitter, in order to reduce the speed
// of emitting the callbacks. Since this is an internal class, that should
// be fine.
function AMQPParser (version, type) {
  this.isClient = (type == 'client');
  this.state = this.isClient ? 'frameHeader' : 'protocolHeader';

  if (version != '0-9-1') this.throwError("Unsupported protocol version");

  var frameHeader = new Buffer(7);
  frameHeader.used = 0;
  var frameBuffer, frameType, frameChannel;

  var self = this;

  function header(data) {
    var fh = frameHeader;
    var needed = fh.length - fh.used;
    data.copy(fh, fh.used, 0, data.length);
    fh.used += data.length; // sloppy
    if (fh.used >= fh.length) {
      fh.read = 0;
      frameType = fh[fh.read++];
      frameChannel = parseInteger(fh, 2, self);
      var frameSize = parseInteger(fh, 4, self);
      fh.used = 0; // for reuse
      if (frameSize > maxFrameBuffer) {
        self.throwError("Oversized frame " + frameSize);
      }
      frameBuffer = new Buffer(frameSize);
      frameBuffer.used = 0;
      return frame(data.slice(needed));
    }
    else { // need more!
      return header;
    }
  }

  function frame(data) {
    var fb = frameBuffer;
    var needed = fb.length - fb.used;
    data.copy(fb, fb.used, 0, data.length);
    fb.used += data.length;
    if (data.length > needed) {
      return frameEnd(data.slice(needed));
    }
    else if (data.length == needed) {
      return frameEnd;
    }
    else {
      return frame;
    }
  }

  function frameEnd(data) {
    if (data.length > 0) {
      if (data[0] === Indicators.FRAME_END) {
        switch (frameType) {
        case FrameType.METHOD:
          self._parseMethodFrame(frameChannel, frameBuffer);
          break;
        case FrameType.HEADER:
          self._parseHeaderFrame(frameChannel, frameBuffer);
          break;
        case FrameType.BODY:
          if (self.onContent) {
            self.onContent(frameChannel, frameBuffer);
          }
          break;
        case FrameType.HEARTBEAT:
          debug("heartbeat");
          if (self.onHeartBeat) self.onHeartBeat();
          break;
        default:
          self.throwError("Unhandled frame type " + frameType);
          break;
        }
        return header(data.slice(1));
      }
      else {
        self.throwError("Missing frame end marker");
      }
    }
    else {
      return frameEnd;
    }
  }

  self.parse = header;
}

// If there's an error in the parser, call the onError handler or throw
AMQPParser.prototype.throwError = function (err) {
  if(this.onError) this.onError(err);
  else this.emit("error", err);
};

// Everytime data is recieved on the socket, pass it to this function for
// parsing.
AMQPParser.prototype.execute = function (data) {
  // This function only deals with dismantling and buffering the frames.
  // It delegates to other functions for parsing the frame-body.
  debug('execute: ' + data.toString());
  this.parse = this.parse(data);
};


// parse Network Byte Order integers. size can be 1,2,4,8
function parseInteger (buffer, size, emitter) {
  var int = 0;
  switch (size) {
    case 1:
      return buffer[buffer.read++];

    case 2:
      return (buffer[buffer.read++] << 8) + buffer[buffer.read++];

    case 4:
      return (buffer[buffer.read++] << 24) + (buffer[buffer.read++] << 16) +
             (buffer[buffer.read++] << 8)  + buffer[buffer.read++];

    case 8:
      return (buffer[buffer.read++] << 56) + (buffer[buffer.read++] << 48) +
             (buffer[buffer.read++] << 40) + (buffer[buffer.read++] << 32) +
             (buffer[buffer.read++] << 24) + (buffer[buffer.read++] << 16) +
             (buffer[buffer.read++] << 8)  + buffer[buffer.read++];

    default:
      emitError(emitter, "cannot parse ints of that size");
  }
}


function parseShortString (buffer) {
  var length = buffer[buffer.read++];
  var s = buffer.toString('utf8', buffer.read, buffer.read+length);
  buffer.read += length;
  return s;
}


function parseLongString (buffer, emitter) {
  var length = parseInteger(buffer, 4, emitter);
  var s = buffer.slice(buffer.read, buffer.read + length);
  buffer.read += length;
  return s.toString();
}


function parseSignedInteger (buffer, emitter) {
  var int = parseInteger(buffer, 4, emitter);
  if (int & 0x80000000) {
    int |= 0xEFFFFFFF;
    int = -int;
  }
  return int;
}

function parseValue (buffer, emitter) {
  switch (buffer[buffer.read++]) {
    case AMQPTypes.STRING:
      return parseLongString(buffer, emitter);

    case AMQPTypes.INTEGER:
      return parseInteger(buffer, 4, emitter);

    case AMQPTypes.DECIMAL:
      var dec = parseInteger(buffer, 1, emitter);
      var num = parseInteger(buffer, 4, emitter);
      return num / (dec * 10);

    case AMQPTypes._64BIT_FLOAT:
      var b = [];
      for (var i = 0; i < 8; ++i)
        b[i] = buffer[buffer.read++];

      return (new jspack(true)).Unpack('d', b);

    case AMQPTypes._32BIT_FLOAT:
      var b = [];
      for (var i = 0; i < 4; ++i)
        b[i] = buffer[buffer.read++];

      return (new jspack(true)).Unpack('f', b);

    case AMQPTypes.TIME:
      var int = parseInteger(buffer, 8, emitter);
      return (new Date()).setTime(int * 1000);

    case AMQPTypes.HASH:
      return parseTable(buffer, emitter);

    case AMQPTypes.SIGNED_64BIT:
      return parseInteger(buffer, 8, emitter);

    case AMQPTypes.BOOLEAN:
      return (parseInteger(buffer, 1, emitter) > 0);

    case AMQPTypes.BYTE_ARRAY:
      var len = parseInteger(buffer, 4, emitter);
      var buf = new Buffer(len);
      buffer.copy(buf, 0, buffer.read, buffer.read + len);
      buffer.read += len;
      return buf;

    case AMQPTypes.ARRAY:
      var len = parseInteger(buffer, 4, emitter);
      var end = buffer.read + len;
      var arr = new Array();

      while (buffer.read < end) {
        arr.push(parseValue(buffer, emitter));
      }

      return arr;

    default:
      emitError(emitter,"Unknown field value type " + buffer[buffer.read-1]);
  }
}

function parseTable (buffer, emitter) {
  var length = buffer.read + parseInteger(buffer, 4, emitter);
  var table = {};

  while (buffer.read < length) {
    table[parseShortString(buffer)] = parseValue(buffer, emitter);
  }
  
  return table;
}

function parseFields (buffer, fields, emitter) {
  var args = {};

  var bitIndex = 0;

  var value;

  for (var i = 0; i < fields.length; i++) {
    var field = fields[i];

    //debug("parsing field " + field.name + " of type " + field.domain);

    switch (field.domain) {
      case 'bit':
        // 8 bits can be packed into one octet.

        // XXX check if bitIndex greater than 7?

        value = (buffer[buffer.read] & (1 << bitIndex)) ? true : false;

        if (fields[i+1] && fields[i+1].domain == 'bit') {
          bitIndex++;
        } else {
          bitIndex = 0;
          buffer.read++;
        }
        break;

      case 'octet':
        value = buffer[buffer.read++];
        break;

      case 'short':
        value = parseInteger(buffer, 2, emitter);
        break;

      case 'long':
        value = parseInteger(buffer, 4, emitter);
        break;

      case 'timestamp':
      case 'longlong':
        value = parseInteger(buffer, 8, emitter);
        break;

      case 'shortstr':
        value = parseShortString(buffer);
        break;

      case 'longstr':
        value = parseLongString(buffer, emitter);
        break;

      case 'table':
        value = parseTable(buffer, emitter);
        break;

      default:
        emitError(emitter,"Unhandled parameter type " + field.domain);
    }
    //debug("got " + value);
    args[field.name] = value;
  }

  return args;
}


AMQPParser.prototype._parseMethodFrame = function (channel, buffer) {
  buffer.read = 0;
  var classId = parseInteger(buffer, 2, this),
     methodId = parseInteger(buffer, 2, this);

  // Make sure that this is a method that we understand.
  if (!methodTable[classId] || !methodTable[classId][methodId]) {
    this.throwError("Received unknown [classId, methodId] pair [" +
               classId + ", " + methodId + "]");
  }

  var method = methodTable[classId][methodId];

  if (!method) this.throwError("bad method?");

  var args = parseFields(buffer, method.fields, this);

  if (this.onMethod) {
    this.onMethod(channel, method, args);
  }
};


AMQPParser.prototype._parseHeaderFrame = function (channel, buffer) {
  buffer.read = 0;

  var classIndex = parseInteger(buffer, 2, this);
  var weight = parseInteger(buffer, 2, this);
  var size = parseInteger(buffer, 8, this);

  var classInfo = classes[classIndex];

  if (classInfo.fields.length > 15) {
    this.throwError("TODO: support more than 15 properties");
  }

  var propertyFlags = parseInteger(buffer, 2, this);

  var fields = [];
  for (var i = 0; i < classInfo.fields.length; i++) {
    var field = classInfo.fields[i];
    // groan.
    if (propertyFlags & (1 << (15-i))) fields.push(field);
  }

  var properties = parseFields(buffer, fields, this);

  if (this.onContentHeader) {
    this.onContentHeader(channel, classInfo, weight, properties, size);
  }
};

function serializeFloat(b, size, value, bigEndian, emitter) {
  var jp = new jspack(bigEndian);

  switch(size) {
  case 4:
    var x = jp.Pack('f', [value]);
    for (var i = 0; i < x.length; ++i)
      b[b.used++] = x[i];
    break;
  
  case 8:
    var x = jp.Pack('d', [value]);
    for (var i = 0; i < x.length; ++i)
      b[b.used++] = x[i];
    break;

  default:
    emitError(emitter,"Unknown floating point size");
  }
}

function serializeInt (b, size, int, emitter) {
  if (b.used + size > b.length) {
    emitError(emitter, "write out of bounds");
  }

  // Only 4 cases - just going to be explicit instead of looping.

  switch (size) {
    // octet
    case 1:
      b[b.used++] = int;
      break;

    // short
    case 2:
      b[b.used++] = (int & 0xFF00) >> 8;
      b[b.used++] = (int & 0x00FF) >> 0;
      break;

    // long
    case 4:
      b[b.used++] = (int & 0xFF000000) >> 24;
      b[b.used++] = (int & 0x00FF0000) >> 16;
      b[b.used++] = (int & 0x0000FF00) >> 8;
      b[b.used++] = (int & 0x000000FF) >> 0;
      break;


    // long long
    case 8:
      b[b.used++] = (int & 0xFF00000000000000) >> 56;
      b[b.used++] = (int & 0x00FF000000000000) >> 48;
      b[b.used++] = (int & 0x0000FF0000000000) >> 40;
      b[b.used++] = (int & 0x000000FF00000000) >> 32;
      b[b.used++] = (int & 0x00000000FF000000) >> 24;
      b[b.used++] = (int & 0x0000000000FF0000) >> 16;
      b[b.used++] = (int & 0x000000000000FF00) >> 8;
      b[b.used++] = (int & 0x00000000000000FF) >> 0;
      break;

    default:
      emitError(emitter,"Bad size");
  }
}


function serializeShortString (b, string, emitter) {
  if (typeof(string) != "string") {
    emitError(emitter,"param must be a string");
  }
  var byteLength = Buffer.byteLength(string, 'utf8');
  if (byteLength > 0xFF) {
    emitError(emitter,"String too long for 'shortstr' parameter");
  }
  if (1 + byteLength + b.used >= b.length) {
    emitError(emitter,"Not enough space in buffer for 'shortstr'");
  }
  b[b.used++] = byteLength;
  b.write(string, b.used, 'utf8');
  b.used += byteLength;
}


function serializeLongString (b, string, emitter) {
  // we accept string, object, or buffer for this parameter.
  // in the case of string we serialize it to utf8.
  if (typeof(string) == 'string') {
    var byteLength = Buffer.byteLength(string, 'utf8');
    serializeInt(b, 4, byteLength, emitter);
    b.write(string, b.used, 'utf8');
    b.used += byteLength;
  } else if (typeof(string) == 'object') {
    serializeTable(b, string, emitter);
  } else {
    // data is Buffer
    var byteLength = string.length;
    serializeInt(b, 4, byteLength, emitter);
    b.write(string, b.used); // memcpy
    b.used += byteLength;
  }
}

function serializeDate(b, date, emitter) {
  serializeInt(b, 8, date.valueOf() / 1000, emitter);
}

function serializeBuffer(b, buffer, emitter) {
  serializeInt(b, 4, buffer.length, emitter);
  buffer.copy(b, b.used, 0);
  b.used += buffer.length;
}

// function serializeBase64(b, buffer, emitter) {
//   serializeLongString(b, buffer.toString('base64'), emitter);
// }

function isBigInt(value) {
  return value > 0xffffffff;
}

function getCode(dec) { 
  var hexArray = "0123456789ABCDEF".split('');
  
  var code1 = Math.floor(dec / 16);
  var code2 = dec - code1 * 16;
  return hexArray[code2];
}

function isFloat(value)
{
  return value === +value && value !== (value|0);
}

function serializeValue (b, value, emitter) {
  switch (typeof(value)) {
    case 'string':
      b[b.used++] = 'S'.charCodeAt(0);
      serializeLongString(b, value, emitter);
      break;

    case 'number':
      if (!isFloat(value)) {
        if (isBigInt(value)) {
          // 64-bit uint
          b[b.used++] = 'l'.charCodeAt(0);
          serializeInt(b, 8, value, emitter);
        } else {
          //32-bit uint
          b[b.used++] = 'I'.charCodeAt(0);
          serializeInt(b, 4, value, emitter);
        }
      } else {
        //64-bit float
        b[b.used++] = 'd'.charCodeAt(0);
        serializeFloat(b, 8, value, false, emitter);
      }
      break;

    case 'boolean':
      b[b.used++] = 't'.charCodeAt(0);
      b[b.used++] = value;
      break;

    default:
    if (value instanceof Date) {
      b[b.used++] = 'T'.charCodeAt(0);
      serializeDate(b, value, emitter);
    } else if (value instanceof Buffer) {
      b[b.used++] = 'x'.charCodeAt(0);
      serializeBuffer(b, value, emitter);
    } else if (util.isArray(value)) {
      b[b.used++] = 'A'.charCodeAt(0);
      serializeArray(b, value, emitter);
    } else if (typeof(value) === 'object') {
      b[b.used++] = 'F'.charCodeAt(0);
      serializeTable(b, value, emitter);
    } else {
      this.throwError("unsupported type in amqp table: " + typeof(value));
    }
  }
}

function serializeTable (b, object, emitter) {
  if (typeof(object) != "object") {
    emitError(emitter, "param must be an object");
  }

  // Save our position so that we can go back and write the length of this table
  // at the beginning of the packet (once we know how many entries there are).
  var lengthIndex = b.used;
  b.used += 4; // sizeof long
  var startIndex = b.used;

  for (var key in object) {
    if (!object.hasOwnProperty(key)) continue;
    serializeShortString(b, key, emitter);
    serializeValue(b, object[key], emitter);
  }

  var endIndex = b.used;
  b.used = lengthIndex;
  serializeInt(b, 4, endIndex - startIndex, emitter);
  b.used = endIndex;
}

function serializeArray (b, arr, emitter) {
  // Save our position so that we can go back and write the byte length of this array
  // at the beginning of the packet (once we have serialized all elements).
  var lengthIndex = b.used;
  b.used += 4; // sizeof long
  var startIndex = b.used;

  len = arr.length;
  for (var i = 0; i < len; i++) {
    serializeValue(b, arr[i], emitter);
  }

  var endIndex = b.used;
  b.used = lengthIndex;
  serializeInt(b, 4, endIndex - startIndex, emitter);
  b.used = endIndex;
}

function emitError(emitter, message) {
  err = "string" == typeof message ? new Error(message) : message;
  emitter.emit("error", err);
}

function serializeFields (buffer, fields, args, strict, emitter) {
  var bitField = 0;
  var bitIndex = 0;
  for (var i = 0; i < fields.length; i++) {
    var field = fields[i];
    var domain = field.domain;
    if (!(field.name in args)) {
      if (strict) {
        emitError(emitter, "Missing field '" + field.name + "' of type '" + domain + "' while executing AMQP method '" + arguments.callee.caller.arguments[1].name + "'");
      }
      continue;
    }

    var param = args[field.name];

    //debug("domain: " + domain + " param: " + param);

    switch (domain) {
      case 'bit':
        if (typeof(param) != "boolean") {
          emitError(emitter, "Unmatched field " + JSON.stringify(field));
        }

        if (param) bitField |= (1 << bitIndex);
        bitIndex++;

        if (!fields[i+1] || fields[i+1].domain != 'bit') {
          debug('SET bit field ' + field.name + ' 0x' + bitField.toString(16));
          buffer[buffer.used++] = bitField;
          bitField = 0;
          bitIndex = 0;
        }
        break;

      case 'octet':
        if (typeof(param) != "number" || param > 0xFF) {
          emitError(emitter, "Unmatched field " + JSON.stringify(field));
        }
        buffer[buffer.used++] = param;
        break;

      case 'short':
        if (typeof(param) != "number" || param > 0xFFFF) {
          emitError(emitter, "Unmatched field " + JSON.stringify(field));
        }
        serializeInt(buffer, 2, param, emitter);
        break;

      case 'long':
        if (typeof(param) != "number" || param > 0xFFFFFFFF) {
          emitError(emitter, "Unmatched field " + JSON.stringify(field));
        }
        serializeInt(buffer, 4, param, emitter);
        break;

      case 'timestamp':
      case 'longlong':
        serializeInt(buffer, 8, param, emitter);
        break;

      case 'shortstr':
        if (typeof(param) != "string" || param.length > 0xFF) {
          emitError(emitter, "Unmatched field " + JSON.stringify(field));
        }
        serializeShortString(buffer, param, emitter);
        break;

      case 'longstr':
        serializeLongString(buffer, param, emitter);
        break;

      case 'table':
        if (typeof(param) != "object") {
          emitError(emitter, "Unmatched field " + JSON.stringify(field));
        }
        serializeTable(buffer, param, emitter);
        break;

      default:
        emitError(emitter, "Unknown domain value type " + domain);
    }
  }
}


function Connection (connectionArgs, options, readyCallback) {
  net.Stream.call(this);

  var self = this;

  this.setOptions(connectionArgs);
  this.setImplOptions(options);

  if (typeof readyCallback === 'function') {
    this._readyCallback = readyCallback;
  }

  var parser;
  var backoffTime = null;
  this.connectionAttemptScheduled = false;

  var backoff = function () {
    if (self._inboundHeartbeatTimer !== null) {
      clearTimeout(self._inboundHeartbeatTimer);
      self._inboundHeartbeatTimer = null;
    }
    if (self._outboundHeartbeatTimer !== null) {
      clearTimeout(self._outboundHeartbeatTimer);
      self._outboundHeartbeatTimer = null;
    }

    if (!self.connectionAttemptScheduled) {
      // Set to true, as we are presently in the process of scheduling one.
      self.connectionAttemptScheduled = true;

      // Kill the socket, if it hasn't been killed already.
      self.end();

      // Reset parser state
      parser = null;

      // In order for our reconnection to be seamless, we have to notify the
      // channels that they are no longer connected so that nobody attempts
      // to send messages which would be doomed to fail.
      for (var channel in self.channels) {
        if (channel != 0) {
          self.channels[channel].state = 'closed';
        }
      }
      // Queues are channels (so we have already marked them as closed), but
      // queues have special needs, since the subscriptions will no longer
      // be known to the server when we reconnect.  Mark the subscriptions as
      // closed so that we can resubscribe them once we are reconnected.
      for (var queue in self.queues) {
        for (var index in self.queues[queue].consumerTagOptions) {
          self.queues[queue].consumerTagOptions[index]['state'] = 'closed';
        }
      }

      // Begin reconnection attempts
      if (self.implOptions.reconnect) {
        // Don't thrash, use a backoff strategy.
        if (backoffTime === null) {
          // This is the first time we've failed since a successful connection,
          // so use the configured backoff time without any modification.
          backoffTime = self.implOptions.reconnectBackoffTime;
        } else if (self.implOptions.reconnectBackoffStrategy === 'exponential') {
          // If you've configured exponential backoff, we'll double the
          // backoff time each subsequent attempt until success.
          backoffTime *= 2;
          // limit the maxium timeout, to avoid potentially unlimited stalls
          if(backoffTime > self.implOptions.reconnectExponentialLimit){
            backoffTime = self.implOptions.reconnectExponentialLimit;
          }

        } else if (self.implOptions.reconnectBackoffStrategy === 'linear') {
          // Linear strategy is the default.  In this case, we will retry at a
          // constant interval, so there's no need to change the backoff time
          // between attempts.
        } else {
          // TODO should we warn people if they picked a nonexistent strategy?
        }

        setTimeout(function () {
          // Set to false, so that if we fail in the reconnect attempt, we can
          // schedule another one.
          self.connectionAttemptScheduled = false;
          self.reconnect();
        }, backoffTime);
      }
    }
  };

  this._defaultExchange = null;
  this.channelCounter = 0;
  this._sendBuffer = new Buffer(maxFrameBuffer);

  self.addListener('connect', function () {
    // In the case where this is a reconnection, do not trample on the existing
    // channels.
    // For your reference, channel 0 is the control channel.
    self.channels = (self.implOptions.reconnect ? self.channels : undefined) || {0:self};
    self.queues = (self.implOptions.reconnect ? self.queues : undefined) || {};
    self.exchanges = (self.implOptions.reconnect ? self.exchanges : undefined) || {};

    parser = new AMQPParser('0-9-1', 'client');

    parser.onMethod = function (channel, method, args) {
      self._onMethod(channel, method, args);
    };

    parser.onContent = function (channel, data) {
      debug(channel + " > content " + data.length);
      if (self.channels[channel] && self.channels[channel]._onContent) {
        self.channels[channel]._onContent(channel, data);
      } else {
        debug("unhandled content: " + data);
      }
    };

    parser.onContentHeader = function (channel, classInfo, weight, properties, size) {
      debug(channel + " > content header " + JSON.stringify([classInfo.name, weight, properties, size]));
      if (self.channels[channel] && self.channels[channel]._onContentHeader) {
        self.channels[channel]._onContentHeader(channel, classInfo, weight, properties, size);
      } else {
        debug("unhandled content header");
      }
    };

    parser.onHeartBeat = function () {
      self.emit("heartbeat");
      debug("heartbeat");
    };

    parser.onError = function (e) {
      self.emit("error", e);
      self.emit("close");
    };
    //debug("connected...");
    // Time to start the AMQP 7-way connection initialization handshake!
    // 1. The client sends the server a version string
    self.write("AMQP" + String.fromCharCode(0,0,9,1));
  });

  self.addListener('data', function (data) {
    if(parser != null){
      parser.execute(data);
    }
    self._inboundHeartbeatTimerReset();
  });

  self.addListener('error', function () {
    backoff();
  });

  self.addListener('ready', function () {
    // Reset the backoff time since we have successfully connected.
    backoffTime = null;

    if (self.implOptions.reconnect) {
      // Reconnect any channels which were open.
      for (var channel in self.channels) {
        if (channel != 0) {
          self.channels[channel].reconnect();
        }
      }
    }

    // Restart the heartbeat to the server
    self._outboundHeartbeatTimerReset();
  })
}
util.inherits(Connection, net.Stream);
exports.Connection = Connection;


var defaultPorts = { 'amqp': 5672, 'amqps': 5671 };

var defaultOptions = { host: 'localhost'
                     , port: defaultPorts['amqp']
                     , login: 'guest'
                     , password: 'guest'
                     , vhost: '/'
                     };
// If the "reconnect" option is true, then the driver will attempt to
// reconnect using the configured strategy *any time* the connection
// becomes unavailable.
// If this is not appropriate for your application, do not set this option.
// If you would like this option, you can set parameters controlling how
// aggressively the reconnections will be attempted.
// Valid strategies are "linear" and "exponential".
// Backoff times are in milliseconds.  Under the "linear" strategy, the driver
// will pause <reconnectBackoffTime> ms before the first attempt, and between
// each subsequent attempt.  Under the "exponential" strategy, the driver will
// pause <reconnectBackoffTime> ms before the first attempt, and will double
// the previous pause between each subsequent attempt until a connection is
// reestablished.
var defaultImplOptions = { defaultExchangeName: '', reconnect: true , reconnectBackoffStrategy: 'linear' , reconnectExponentialLimit: 120000, reconnectBackoffTime: 1000 };

function urlOptions(connectionString, emitter) {
  var opts = {};
  var url = URL.parse(connectionString);
  var scheme = url.protocol.substring(0, url.protocol.lastIndexOf(':'));
  if (scheme != 'amqp' && scheme != 'amqps') {
    emitError(emitter,'Connection URI must use amqp or amqps scheme. ' +
                    'For example, "amqp://bus.megacorp.internal:5766".');
  }
  opts.ssl = ('amqps' === scheme);
  opts.host = url.hostname;
  opts.port = url.port || defaultPorts[scheme]
  if (url.auth) {
    var auth = url.auth.split(':');
    auth[0] && (opts.login = auth[0]);
    auth[1] && (opts.password = auth[1]);
  }
  if (url.pathname) {
    opts.vhost = unescape(url.pathname.substr(1));
  }
  return opts;
}

exports.createConnection = function (connectionArgs, options, readyCallback) {
  var c = new Connection(connectionArgs, options, readyCallback);
  // c.setOptions(connectionArgs);
  // c.setImplOptions(options);
  c.connect();
  return c;
};

Connection.prototype.setOptions = function (options) {
  var o  = {};
  var urlo = (options && options.url) ? urlOptions(options.url, this) : {};
  mixin(o, defaultOptions, urlo, options || {});
  this.options = o;
};

Connection.prototype.setImplOptions = function (options) {
  var o = {}
  mixin(o, defaultImplOptions, options || {});
  this.implOptions = o;
};

Connection.prototype.reconnect = function () {
  // Suspend activity on channels
  for (var channel in this.channels) {
    this.channels[channel].state = 'closed';
  }
  // Terminate socket activity
  this.end();
  this.connect();
};

Connection.prototype.connect = function () {
  // If you pass a array of hosts, lets choose a random host, or then next one.
  var connectToHost = this.options.host;

  if(Array.isArray(this.options.host) == true){
    if(this.hosti == null){
      this.hosti = Math.random()*this.options.host.length >> 0;
    }else{
      this.hosti = (this.hosti+1) % this.options.host.length;
    }
    connectToHost = this.options.host[this.hosti]
  }

  // Connect socket
  net.Socket.prototype.connect.call(this, this.options.port, connectToHost);

};

Connection.prototype._onMethod = function (channel, method, args) {
  debug(channel + " > " + method.name + " " + JSON.stringify(args));

  // Channel 0 is the control channel. If not zero then delegate to
  // one of the channel objects.

  if (channel > 0) {
    if (!this.channels[channel]) {
      debug("Received message on untracked channel.");
      return;
    }
    if (!this.channels[channel]._onChannelMethod) {
      emitError(this, 'Channel ' + channel + ' has no _onChannelMethod method.');
    }
    this.channels[channel]._onChannelMethod(channel, method, args);
    return;
  }

  // channel 0

  switch (method) {
    // 2. The server responds, after the version string, with the
    // 'connectionStart' method (contains various useless information)
    case methods.connectionStart:
      // We check that they're serving us AMQP 0-9
      if (args.versionMajor != 0 && args.versionMinor != 9) {
        this.end();
        this.emit('error', new Error("Bad server version"));
        return;
      }
      this.serverProperties = args.serverProperties;
      // 3. Then we reply with StartOk, containing our useless information.
      this._sendMethod(0, methods.connectionStartOk,
          { clientProperties:
            { version: '0.0.1'
            , platform: 'node-' + process.version
            , product: 'node-amqp'
            }
          , mechanism: 'AMQPLAIN'
          , response:
            { LOGIN: this.options.login
            , PASSWORD: this.options.password
            }
          , locale: 'en_US'
          });
      break;

    // 4. The server responds with a connectionTune request
    case methods.connectionTune:
      // 5. We respond with connectionTuneOk
      this._sendMethod(0, methods.connectionTuneOk,
          { channelMax: 0
          , frameMax: maxFrameBuffer
          , heartbeat: this.options.heartbeat || 0
          });
      // 6. Then we have to send a connectionOpen request
      this._sendMethod(0, methods.connectionOpen,
          { virtualHost: this.options.vhost
          // , capabilities: ''
          // , insist: true
          , reserved1: ''
          , reserved2: true
          });
      break;


    case methods.connectionOpenOk:
      // 7. Finally they respond with connectionOpenOk
      // Whew! That's why they call it the Advanced MQP.
      if (this._readyCallback) {
        this._readyCallback(this);
        this._readyCallback = null;
      }
      this.emit('ready');
      break;

    case methods.connectionClose:
      var e = new Error(args.replyText);
      e.code = args.replyCode;
      if (!this.listeners('close').length && !this.implOptions.reconnect) {
        console.log('Unhandled connection error: ' + args.replyText);
      }
      this.destroy(e);
      break;

    default:
      emitError(this, "Uncaught method '" + method.name + "' with args " +
          JSON.stringify(args));
  }
};

Connection.prototype.heartbeat = function () {
  this.write(new Buffer([8,0,0,0,0,0,0,206]));
};

Connection.prototype._outboundHeartbeatTimerReset = function () {
  if (this._outboundHeartbeatTimer !== null) {
    clearTimeout(this._outboundHeartbeatTimer);
    this._outboundHeartbeatTimer = null;
  }
  if (this.options.heartbeat) {
    var self = this;
    this._outboundHeartbeatTimer = setTimeout(function () {
      self.heartbeat();
      self._outboundHeartbeatTimerReset();
    }, 1000 * this.options.heartbeat);
  }
};

Connection.prototype._inboundHeartbeatTimerReset = function () {
  if (this._inboundHeartbeatTimer !== null) {
    clearTimeout(this._inboundHeartbeatTimer);
    this._inboundHeartbeatTimer = null;
  }
  if (this.options.heartbeat) {
    var self = this;
    var gracePeriod = 2 * this.options.heartbeat;
    this._inboundHeartbeatTimer = setTimeout(function () {
      emitError(self, 'no heartbeat or data in last ' + gracePeriod + ' seconds');
    }, gracePeriod * 1000);
  }
};

Connection.prototype._sendMethod = function (channel, method, args) {
  debug(channel + " < " + method.name + " " + JSON.stringify(args));
  var b = this._sendBuffer;
  b.used = 0;

  b[b.used++] = 1; // constants.frameMethod

  serializeInt(b, 2, channel, this);

  var lengthIndex = b.used;

  serializeInt(b, 4, 42, this); // replace with actual length.

  var startIndex = b.used;


  serializeInt(b, 2, method.classIndex, this); // short, classId
  serializeInt(b, 2, method.methodIndex, this); // short, methodId

  serializeFields(b, method.fields, args, true, this);

  var endIndex = b.used;

  // write in the frame length now that we know it.
  b.used = lengthIndex;
  serializeInt(b, 4, endIndex - startIndex, this);
  b.used = endIndex;

  b[b.used++] = 206; // constants.frameEnd;

  var c = b.slice(0, b.used);

  //debug("sending frame: " + c);

  this.write(c);
  
  this._outboundHeartbeatTimerReset();
};


// connection: the connection
// channel: the channel to send this on
// size: size in bytes of the following message
// properties: an object containing any of the following:
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
function sendHeader (connection, channel, size, properties) {
  var b = new Buffer(maxFrameBuffer); // FIXME allocating too much.
                                      // use freelist?
  b.used = 0;

  var classInfo = classes[60]; // always basic class.

  // 7 OCTET FRAME HEADER

  b[b.used++] = 2; // constants.frameHeader

  serializeInt(b, 2, channel, connection);

  var lengthStart = b.used;

  serializeInt(b, 4, 0 /*dummy*/, connection); // length

  var bodyStart = b.used;

  // HEADER'S BODY

  serializeInt(b, 2, classInfo.index, connection);   // class 60 for Basic
  serializeInt(b, 2, 0, connection);                 // weight, always 0 for rabbitmq
  serializeInt(b, 8, size, connection);              // byte size of body

  // properties - first propertyFlags
  var props = {'contentType': 'application/octet-stream'};
  mixin(props, properties);
  var propertyFlags = 0;
  for (var i = 0; i < classInfo.fields.length; i++) {
    if (props[classInfo.fields[i].name]) propertyFlags |= 1 << (15-i);
  }
  serializeInt(b, 2, propertyFlags, connection);
  // now the actual properties.
  serializeFields(b, classInfo.fields, props, false, connection);

  //serializeTable(b, props);

  var bodyEnd = b.used;

  // Go back to the header and write in the length now that we know it.
  b.used = lengthStart;
  serializeInt(b, 4, bodyEnd - bodyStart, connection);
  b.used = bodyEnd;

  // 1 OCTET END

  b[b.used++] = 206; // constants.frameEnd;

  var s = b.slice(0, b.used);

  //debug('header sent: ' + JSON.stringify(s));

  connection.write(s);
}


Connection.prototype._sendBody = function (channel, body, properties) {
  // Handles 3 cases
  // - body is utf8 string
  // - body is instance of Buffer
  // - body is an object and its JSON representation is sent

  // Does not handle the case for streaming bodies.

  // In order to support long frame types we switch our strings into buffers for proper handling
  if (typeof(body) == 'string') {
    body = new Buffer(body, 'utf8');
  }

  if (typeof(body) == 'object' && !(body instanceof Buffer)){
    properties = mixin({contentType: 'application/json' }, properties);  
    body = new Buffer(JSON.stringify(body), 'utf8');
  }
  
  if (body instanceof Buffer) {
    sendHeader(this, channel, body.length, properties);

    debug('body sent: ' + JSON.stringify(b));

    for (var offset = 0; offset < body.length; offset += maxFrameSize){

      var remaining = body.length - offset;
      var fragmentLength = (remaining < maxFrameSize) ? remaining : maxFrameSize;

      // debug("sending " + offset + " through " + (offset+fragmentLength) + " of " + body.length)

      var b = new Buffer(7);
      b.used = 0;
      b[b.used++] = 3; // constants.frameBody
      serializeInt(b, 2, channel, this);
      serializeInt(b, 4, fragmentLength, this);

      this.write(b);
      this.write(body.slice(offset,offset+fragmentLength));

      this.write(new Buffer([206])); // frameEnd
  
    }
    return true;

  }else{
    debug('invalid body sent to _sendBody');
    return false;
  }
};


// Options
// - passive (boolean)
// - durable (boolean)
// - exclusive (boolean)
// - autoDelete (boolean, default true)
Connection.prototype.queue = function (name /* options, openCallback */) {
  var options, callback;
  if (typeof arguments[1] == 'object') {
    options = arguments[1];
    callback = arguments[2];
  } else {
    callback = arguments[1];
  }

  this.channelCounter++;
  var channel = this.channelCounter;

  var q = new Queue(this, channel, name, options, callback);
  this.channels[channel] = q;
  return q;
};

// remove a queue when it's closed (called from Queue)
Connection.prototype.queueClosed = function (name) {
  if (this.queues[name]) delete this.queues[name];
};

// remove an exchange when it's closed (called from Exchange)
Connection.prototype.exchangeClosed = function (name) {
  if (this.exchanges[name]) delete this.exchanges[name];
};


// connection.exchange('my-exchange', { type: 'topic' });
// Options
// - type 'fanout', 'direct', or 'topic' (default)
// - passive (boolean)
// - durable (boolean)
// - autoDelete (boolean, default true)
Connection.prototype.exchange = function (name, options, openCallback) {
  if (name === undefined) name = this.implOptions.defaultExchangeName;

  if (!options) options = {};
  if (name != '' && options.type === undefined) options.type = 'topic';

  this.channelCounter++;
  var channel = this.channelCounter;
  var exchange = new Exchange(this, channel, name, options, openCallback);
  this.channels[channel] = exchange;
  this.exchanges[name] = exchange;
  return exchange;
};

// Publishes a message to the default exchange.
Connection.prototype.publish = function (routingKey, body, options) {
  if (!this._defaultExchange) this._defaultExchange = this.exchange();
    return this._defaultExchange.publish(routingKey, body, options);
};



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
function Message (queue, args) {
  var msgProperties = classes[60].fields;

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
}
util.inherits(Message, events.EventEmitter);


// Acknowledge receipt of message.
// Set first arg to 'true' to acknowledge this and all previous messages
// received on this queue.
Message.prototype.acknowledge = function (all) {
  this.queue.connection._sendMethod(this.queue.channel, methods.basicAck,
      { reserved1: 0
      , deliveryTag: this.deliveryTag
      , multiple: !!all
      });
};

// Reject an incoming message.
// Set first arg to 'true' to requeue the message.
Message.prototype.reject = function (requeue){
  this.queue.connection._sendMethod(this.queue.channel, methods.basicReject,
      { deliveryTag: this.deliveryTag
      , requeue: !!requeue
      });
}

// This class is not exposed to the user. Queue and Exchange are subclasses
// of Channel. This just provides a task queue.
function Channel (connection, channel) {
  events.EventEmitter.call(this);

  this.channel = channel;
  this.connection = connection;
  this._tasks = [];

  this.reconnect();
}
util.inherits(Channel, events.EventEmitter);

Channel.prototype.closeOK = function() {
    this.connection._sendMethod(this.channel, methods.channelCloseOk, {reserved1: ""});
}

Channel.prototype.reconnect = function () {
  this.connection._sendMethod(this.channel, methods.channelOpen, {reserved1: ""});
};


Channel.prototype._taskPush = function (reply, cb) {
  var promise = new Promise();
  this._tasks.push({ promise: promise
                   , reply: reply
                   , sent: false
                   , cb: cb
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
        delete this.connection.channels[this.channel]
        this.state = 'closed'
    default:
        this._onMethod(channel, method, args);
    }
}

Channel.prototype.close = function() {
    this.state = 'closing';
    this.connection._sendMethod(this.channel, methods.channelClose,
                                {'replyText': 'Goodbye from node',
                                 'replyCode': 200,
                                 'classId': 0,
                                 'methodId': 0});
}

function closeChannelHelper(inst, consumerTag) {
  return function () {
    if (inst.options.closeChannelOnUnsubscribe) {
      inst.close();
    }
    if (consumerTag != null) {
      delete inst.consumerTagListeners[consumerTag];
      delete inst.consumerTagOptions[consumerTag];
    }
  };
}

function Queue (connection, channel, name, options, callback) {
  Channel.call(this, connection, channel);

  this.name = name;
  this.consumerTagListeners = {};
  this.consumerTagOptions = {};
  var self = this;
  
  // route messages to subscribers based on consumerTag
  this.on('rawMessage', function(message) {
    if (message.consumerTag && self.consumerTagListeners[message.consumerTag]) {
      self.consumerTagListeners[message.consumerTag](message);
    }
  });
  
  this.options = { autoDelete: true, closeChannelOnUnsubscribe: false };
  if (options) mixin(this.options, options);

  this._openCallback = callback;
}
util.inherits(Queue, Channel);

Queue.prototype.subscribeRaw = function (/* options, messageListener */) {
  var self = this;

  var messageListener = arguments[arguments.length-1];
  var consumerTag = 'node-amqp-'+process.pid+'-'+Math.random();
  this.consumerTagListeners[consumerTag] = messageListener;

  var options = { };
  if (typeof arguments[0] == 'object') {
    mixin(options, arguments[0]);
  }
  options['state'] = 'opening';
  this.consumerTagOptions[consumerTag] = options;

  if (options.prefetchCount) {
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
        , noLocal: options.noLocal ? true : false
        , noAck: options.noAck ? true : false
        , exclusive: options.exclusive ? true : false
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
  .addCallback(closeChannelHelper(self, consumerTag));
};

Queue.prototype.subscribe = function (/* options, messageListener */) {
  var self = this;

  var messageListener = arguments[arguments.length-1];
  if(typeof(messageListener) !== "function") messageListener = null;

  var options = { ack: false,
                  prefetchCount: 1,
                  routingKeyInPayload: self.connection.options.routingKeyInPayload,
                  deliveryTagInPayload: self.connection.options.deliveryTagInPayload };
  if (typeof arguments[0] == 'object') {
    if (arguments[0].ack) options.ack = true;
    if (arguments[0].routingKeyInPayload)
      options.routingKeyInPayload = arguments[0].routingKeyInPayload;
    if (arguments[0].deliveryTagInPayload)
      options.deliveryTagInPayload = arguments[0].deliveryTagInPayload;
    if (arguments[0].prefetchCount != undefined)
      options.prefetchCount = arguments[0].prefetchCount;

  }

  // basic consume
  var rawOptions = { noAck: !options.ack };
  if (options.ack) {
    rawOptions['prefetchCount'] = options.prefetchCount;
  }
  return this.subscribeRaw(rawOptions, function (m) {
    var contentType = m.contentType;
    
    if (contentType == null && m.headers && m.headers.properties) {
       contentType = m.headers.properties.content_type;
    }
    
    var isJSON = (contentType == 'text/json') || (contentType == 'application/json');

    var b;

    if (isJSON) {
      b = ""
    } else {
      b = new Buffer(m.size);
      b.used = 0;
    }

    self._lastMessage = m;

    m.addListener('data', function (d) {
      if (isJSON) {
        b += d.toString();
      } else {
        d.copy(b, b.used);
        b.used += d.length;
      }
    });

    m.addListener('end', function () {
      var json, deliveryInfo = {}, msgProperties = classes[60].fields;
      if (isJSON) {
        try {
          json = JSON.parse(b);
        } catch (e) {
          json = null;
          deliveryInfo.parseError = e;
          deliveryInfo.rawData = b;
        }
      } else {
        json = { data: b, contentType: m.contentType };
      }
      for (var i=0, l=msgProperties.length; i<l; i++) {
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
      for (var i in this.headers) {
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
Queue.prototype.shift = function () {
  if (this._lastMessage) {
    this._lastMessage.acknowledge();
  }
};


Queue.prototype.bind = function (/* [exchange,] routingKey [, bindCallback] */) {
  var self = this;

  // The first argument, exchange is optional.
  // If not supplied the connection will use the 'amq.topic'
  // exchange.

    var exchange, routingKey, callback;
    if(typeof(arguments[arguments.length-1]) == 'function'){
        callback = arguments[arguments.length-1];
    }
    // Remove callback from args so rest of bind functionality works as before
    // Also, defend against cases where a non function callback has been passed as 3rd param
    if (callback || arguments.length == 3) {
        delete arguments[arguments.length-1];
        arguments.length--;
    }
    
  if (arguments.length == 2) {
    exchange = arguments[0];
    routingKey = arguments[1];
  } else {
    exchange = 'amq.topic';
    routingKey = arguments[0];
  }
  if(callback) this._bindCallback = callback;


  var exchangeName = exchange instanceof Exchange ? exchange.name : exchange;

  if(exchangeName in self.connection.exchanges) {
    this.exchange = self.connection.exchanges[exchangeName];
    this.exchange.binds++;
  }

  self.connection._sendMethod(self.channel, methods.queueBind,
      { reserved1: 0
      , queue: self.name
      , exchange: exchangeName
      , routingKey: routingKey
      , noWait: false
      , "arguments": {}
      });

};

Queue.prototype.unbind = function (/* [exchange,] routingKey */) {
  var self = this;

  // The first argument, exchange is optional.
  // If not supplied the connection will use the default 'amq.topic'
  // exchange.

  var exchange, routingKey;

  if (arguments.length == 2) {
    exchange = arguments[0];
    routingKey = arguments[1];
  } else {
    exchange = 'amq.topic';
    routingKey = arguments[0];
  }


  return this._taskPush(methods.queueUnbindOk, function () {
    var exchangeName = exchange instanceof Exchange ? exchange.name : exchange;
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
  })
  .addCallback(closeChannelHelper(self)); //TODO: test commenting this out.
};

Queue.prototype.purge = function() {
  var self = this;
  return this._taskPush(methods.queuePurgeOk, function () {
    self.connection._sendMethod(self.channel, methods.queuePurge,
                                 { reserved1 : 0,
                                 queue: self.name,
                                 noWait: false})
  });
};


Queue.prototype._onMethod = function (channel, method, args) {
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
            , passive: this.options.passive ? true : false
            , durable: this.options.durable ? true : false
            , exclusive: this.options.exclusive ? true : false
            , autoDelete: this.options.autoDelete ? true : false
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
      if (this._openCallback) {
        this._openCallback(this);
        this._openCallback = null;
      }
      // TODO this is legacy interface, remove me
      this.emit('open', args.queue, args.messageCount, args.consumerCount);
      
      // If this is a reconnect, we must re-subscribe our queue listeners.
      var consumerTags = Object.keys(this.consumerTagListeners);
      for (var index in consumerTags) {
        if (this.consumerTagOptions[consumerTags[index]]['state'] === 'closed') {
          this.subscribeRaw(this.consumerTagOptions[consumerTags[index]], this.consumerTagListeners[consumerTags[index]]);
          // Having called subscribeRaw, we are now a new consumer with a new consumerTag.
          delete this.consumerTagListeners[consumerTags[index]];
          delete this.consumerTagOptions[consumerTags[index]];
        }
      }
      break;

    case methods.basicConsumeOk:
      debug('basicConsumeOk', util.inspect(args, null));
      break;

    case methods.queueBindOk:
        if (this._bindCallback) {
            // setting this._bindCallback to null before calling the callback allows for a subsequent bind within the callback
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
      this.closeOK()
      this.connection.queueClosed(this.name);
      var e = new Error(args.replyText);
      e.code = args.replyCode;
      this.emit('error', e);
      this.emit('close');
      break;
    
    case methods.channelCloseOk:
      this.connection.queueClosed(this.name);
      this.emit('close')
      break;
    
    case methods.basicDeliver:
      this.currentMessage = new Message(this, args);
      break;

    case methods.queueDeleteOk:
      break;

    default:
      emitError(this, "Uncaught method '" + method.name + "' with args " +
          JSON.stringify(args) + "; tasks = " + JSON.stringify(this._tasks));
  }

  this._tasksFlush();
};


Queue.prototype._onContentHeader = function (channel, classInfo, weight, properties, size) {
  mixin(this.currentMessage, properties);
  this.currentMessage.read = 0;
  this.currentMessage.size = size;

  this.emit('rawMessage', this.currentMessage);
};

Queue.prototype._onContent = function (channel, data) {
  this.currentMessage.read += data.length
  this.currentMessage.emit('data', data);
  if (this.currentMessage.read == this.currentMessage.size) {
    this.currentMessage.emit('end');
  }
};

Queue.prototype.flow = function(active) {
    var self = this;
    return this._taskPush(methods.channelFlowOk, function () {
        self.connection._sendMethod(self.channel, methods.channelFlow, {'active': active });
      })
};



function Exchange (connection, channel, name, options, openCallback) {
  Channel.call(this, connection, channel);
  this.name = name;
  this.binds = 0; // keep track of queues bound
  this.options = options || { autoDelete: true};
  this._openCallback = openCallback;

  this._sequence = null;
  this._unAcked  = {};
}
util.inherits(Exchange, Channel);



Exchange.prototype._onMethod = function (channel, method, args) {
  this.emit(method.name, args);
  if (this._handleTaskReply.apply(this, arguments)) return true;

  switch (method) {
    case methods.channelOpenOk:
      // Pre-baked exchanges don't need to be declared
      if (/^$|(amq\.)/.test(this.name)) {
        this.state = 'open';
        // - issue #33 fix
        if (this._openCallback) {
         this._openCallback(this);
         this._openCallback = null;
        }
        // --
        this.emit('open');
       
      // For if we want to delete a exchange, 
      // we dont care if all of the options match.
      } else if (this.options.noDeclare){

        this.state = 'open';

        if (this._openCallback) {
         this._openCallback(this);
         this._openCallback = null;
        }

        this.emit('open');
      } else {
        this.connection._sendMethod(channel, methods.exchangeDeclare,
            { reserved1:  0
            , reserved2:  false
            , reserved3:  false
            , exchange:   this.name
            , type:       this.options.type || 'topic'
            , passive:    !!this.options.passive
            , durable:    !!this.options.durable
            , autoDelete: !!this.options.autoDelete
            , internal:   !!this.options.internal
            , noWait:     false
            , "arguments":this.options.arguments || {}
            });
        this.state = 'declaring';
      }
      break;

     case methods.exchangeDeclareOk:

      if (this.options.confirm){
        this.connection._sendMethod(channel, methods.confirmSelect,
          { noWait: false });
      }else{

        this.state = 'open';
        this.emit('open');
        if (this._openCallback) {
          this._openCallback(this);
          this._openCallback = null;
        }
      }

      break;

    case methods.exchangeBindOk:
      if (this._bindCallback) {
        // setting this._bindCallback to null before calling the callback allows for a subsequent bind within the callback
        var cb = this._bindCallback;
        this._bindCallback = null;
        cb(this);
      }
      break;

    case methods.confirmSelectOk:
      this._sequence = 1;
      
      this.state = 'open';
      this.emit('open');
      if (this._openCallback) {
        this._openCallback(this);
        this._openCallback = null;
      }
      break;

    case methods.channelClose:
      this.state = "closed";
      this.closeOK();
      this.connection.exchangeClosed(this.name);
      var e = new Error(args.replyText);
      e.code = args.replyCode;
      this.emit('error', e);
      this.emit('close');
      break;

    case methods.channelCloseOk:
      this.connection.exchangeClosed(this.name);
      this.emit('close');
      break;


    case methods.basicAck:
      this.emit('basic-ack', args);

      if(args.deliveryTag == 0 && args.multiple == true){
        // we must ack everything
        for(var tag in this._unAcked){
          this._unAcked[tag].emitAck()
          delete this._unAcked[tag]
        }
      }else if(args.deliveryTag != 0 && args.multiple == true){
        // we must ack everything before the delivery tag
        for(var tag in this._unAcked){
          if(tag <= args.deliveryTag){
            this._unAcked[tag].emitAck()
            delete this._unAcked[tag]
          }
        }
      }else if(this._unAcked[args.deliveryTag] && args.multiple == false){
        // simple single ack
        this._unAcked[args.deliveryTag].emitAck()
        delete this._unAcked[args.deliveryTag]
      }
      
      break;

    case methods.basicReturn:
      this.emit('basic-return', args);
      break;

    default:
      emitError(this, "Uncaught method '" + method.name + "' with args " +
          JSON.stringify(args));
  }

  this._tasksFlush();
};

Exchange.prototype.bind = function (exchange, routingKey, callback) {
  var self = this;

  if(callback) this._bindCallback = callback;

  var exchangeName = exchange instanceof Exchange ? exchange.name : exchange;

  if(exchangeName in self.connection.exchanges) {
    this.exchange = self.connection.exchanges[exchangeName];
    this.exchange.binds++;
  }

  self.connection._sendMethod(self.channel, methods.exchangeBind,
      { reserved1: 0
      , destination: self.name
      , source: exchangeName
      , routingKey: routingKey
      , noWait: false
      , "arguments": {}
      });

};

Exchange.prototype.unbind = function (exchange, routingKey) {
  var self = this;

  return this._taskPush(methods.exchangeUnbindOk, function () {
    var exchangeName = exchange instanceof Exchange ? exchange.name : exchange;
    self.connection._sendMethod(self.channel, methods.exchangeUnbind,
        { reserved1: 0
        , destination: self.name
        , source: exchangeName
        , routingKey: routingKey
        , noWait: false
        , "arguments": {}
        });
  });
};

// exchange.publish('routing.key', 'body');
//
// the third argument can specify additional options
// - mandatory (boolean, default false)
// - immediate (boolean, default false)
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
// 
// the callback is optional and is only used when confirm is turned on for the exchange

Exchange.prototype.publish = function (routingKey, data, options, callback) {
  var self = this;

  options = options || {};
  options.routingKey = routingKey;
  options.exchange   = self.name;
  options.mandatory  = options.mandatory ? true : false;
  options.immediate  = options.immediate ? true : false;
  options.reserved1  = 0;

  var task = this._taskPush(null, function () {
    self.connection._sendMethod(self.channel, methods.basicPublish, options);
    // This interface is probably not appropriate for streaming large files.
    // (Of course it's arguable about whether AMQP is the appropriate
    // transport for large files.) The content header wants to know the size
    // of the data before sending it - so there's no point in trying to have a
    // general streaming interface - streaming messages of unknown size simply
    // isn't possible with AMQP. This is all to say, don't send big messages.
    // If you need to stream something large, chunk it yourself.
    self.connection._sendBody(self.channel, data, options);
  });

  if (self.options.confirm){
    task.sequence = self._sequence
    self._unAcked[self._sequence] = task
    self._sequence++

    if(callback != null){
      var errorCallback = function(){task.removeAllListeners();callback(true)};
      var exchange = this;
      task.once('ack',   function(){exchange.removeListener('error', errorCallback); task.removeAllListeners();callback(false)}); 
      this.once('error', errorCallback);
    }
  }

  return task
};

// do any necessary cleanups eg. after queue destruction  
Exchange.prototype.cleanup = function() {
  if (this.binds == 0) // don't keep reference open if unused
      this.connection.exchangeClosed(this.name);
};


Exchange.prototype.destroy = function (ifUnused) {
  var self = this;
  return this._taskPush(methods.exchangeDeleteOk, function () {
    self.connection.exchangeClosed(self.name);
    self.connection._sendMethod(self.channel, methods.exchangeDelete,
        { reserved1: 0
        , exchange: self.name
        , ifUnused: ifUnused ? true : false
        , noWait: false
        });
  });
};
