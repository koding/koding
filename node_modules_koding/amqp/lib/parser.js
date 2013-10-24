'use strict';
var events = require('events');
var util = require('util');
var net = require('net');
var tls = require('tls');
var fs = require('fs');
var debug = require('./debug');
var jspack = require('../jspack').jspack;
var AMQPTypes = require('./constants').AMQPTypes;
var Indicators = require('./constants').Indicators;
var FrameType = require('./constants').FrameType;
var definitions = require('./definitions');
var methodTable = definitions.methodTable;
var classes = definitions.classes;
    
// parser

var maxFrameBuffer = 131072; // 128k, same as rabbitmq (which was
                             // copying qpid)

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
var AMQPParser = module.exports = function AMQPParser (version, type) {
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
      frameChannel = parseInt(fh, 2);
      var frameSize = parseInt(fh, 4);
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
    var sourceEnd = (fb.length > data.length) ? data.length : fb.length;
    data.copy(fb, fb.used, 0, sourceEnd);
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
AMQPParser.prototype.throwError = function (error) {
  if(this.onError) this.onError(error);
  else throw new Error(error);
};

// Everytime data is recieved on the socket, pass it to this function for
// parsing.
AMQPParser.prototype.execute = function (data) {
  // This function only deals with dismantling and buffering the frames.
  // It delegates to other functions for parsing the frame-body.
  debug('execute: ' + data.toString('hex'));
  this.parse = this.parse(data);
};


// parse Network Byte Order integers. size can be 1,2,4,8
function parseInt (buffer, size) {
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
      throw new Error("cannot parse ints of that size");
  }
}


function parseShortString (buffer) {
  var length = buffer[buffer.read++];
  var s = buffer.toString('utf8', buffer.read, buffer.read+length);
  buffer.read += length;
  return s;
}


function parseLongString (buffer) {
  var length = parseInt(buffer, 4);
  var s = buffer.slice(buffer.read, buffer.read + length);
  buffer.read += length;
  return s.toString();
}


function parseSignedInteger (buffer) {
  var int = parseInt(buffer, 4);
  if (int & 0x80000000) {
    int |= 0xEFFFFFFF;
    int = -int;
  }
  return int;
}

function parseValue (buffer) {
  switch (buffer[buffer.read++]) {
    case AMQPTypes.STRING:
      return parseLongString(buffer);

    case AMQPTypes.INTEGER:
      return parseInt(buffer, 4);

    case AMQPTypes.DECIMAL:
      var dec = parseInt(buffer, 1);
      var num = parseInt(buffer, 4);
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
      var int = parseInt(buffer, 8);
      return (new Date()).setTime(int * 1000);

    case AMQPTypes.HASH:
      return parseTable(buffer);

    case AMQPTypes.SIGNED_64BIT:
      return parseInt(buffer, 8);

    case AMQPTypes.BOOLEAN:
      return (parseInt(buffer, 1) > 0);

    case AMQPTypes.BYTE_ARRAY:
      var len = parseInt(buffer, 4);
      var buf = new Buffer(len);
      buffer.copy(buf, 0, buffer.read, buffer.read + len);
      buffer.read += len;
      return buf;

    case AMQPTypes.ARRAY:
      var len = parseInt(buffer, 4);
      var end = buffer.read + len;
      var arr = [];

      while (buffer.read < end) {
        arr.push(parseValue(buffer));
      }

      return arr;

    default:
      throw new Error("Unknown field value type " + buffer[buffer.read-1]);
  }
}

function parseTable (buffer) {
  var length = buffer.read + parseInt(buffer, 4);
  var table = {};

  while (buffer.read < length) {
    table[parseShortString(buffer)] = parseValue(buffer);
  }
  
  return table;
}

function parseFields (buffer, fields) {
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
        value = parseInt(buffer, 2);
        break;

      case 'long':
        value = parseInt(buffer, 4);
        break;

      // In a previous version this shared code with 'longlong', which caused problems when passed Date 
      // integers. Nobody expects to pass a Buffer here, 53 bits is still 28 million years after 1970, we'll be fine.
      case 'timestamp':
        value = parseInt(buffer, 8);
        break;

      // JS doesn't support 64-bit Numbers, so we expect if you're using 'longlong' that you've
      // used a Buffer instead
      case 'longlong':
        value = new Buffer(8);
        for (var j = 0; j < 8; j++) {
            value[j] = buffer[buffer.read++];
        }
        break;

      case 'shortstr':
        value = parseShortString(buffer);
        break;

      case 'longstr':
        value = parseLongString(buffer);
        break;

      case 'table':
        value = parseTable(buffer);
        break;

      default:
        throw new Error("Unhandled parameter type " + field.domain);
    }
    //debug("got " + value);
    args[field.name] = value;
  }

  return args;
}


AMQPParser.prototype._parseMethodFrame = function (channel, buffer) {
  buffer.read = 0;
  var classId = parseInt(buffer, 2),
     methodId = parseInt(buffer, 2);

  // Make sure that this is a method that we understand.
  if (!methodTable[classId] || !methodTable[classId][methodId]) {
    this.throwError("Received unknown [classId, methodId] pair [" +
               classId + ", " + methodId + "]");
  }

  var method = methodTable[classId][methodId];

  if (!method) this.throwError("bad method?");

  var args = parseFields(buffer, method.fields);

  if (this.onMethod) {
    debug("Executing method", channel, method, args);
    this.onMethod(channel, method, args);
  }
};


AMQPParser.prototype._parseHeaderFrame = function (channel, buffer) {
  buffer.read = 0;

  var classIndex = parseInt(buffer, 2);
  var weight = parseInt(buffer, 2);
  var size = parseInt(buffer, 8);

  var classInfo = classes[classIndex];

  if (classInfo.fields.length > 15) {
    this.throwError("TODO: support more than 15 properties");
  }

  var propertyFlags = parseInt(buffer, 2);

  var fields = [];
  for (var i = 0; i < classInfo.fields.length; i++) {
    var field = classInfo.fields[i];
    // groan.
    if (propertyFlags & (1 << (15-i))) fields.push(field);
  }

  var properties = parseFields(buffer, fields);

  if (this.onContentHeader) {
    this.onContentHeader(channel, classInfo, weight, properties, size);
  }
};