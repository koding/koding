'use strict';
var jspack = require('../jspack').jspack;

var serializer = module.exports = {
  serializeFloat: function(b, size, value, bigEndian) {
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
      throw new Error("Unknown floating point size");
    }
  },

  serializeInt: function (b, size, int) {
    if (b.used + size > b.length) {
      throw new Error("write out of bounds");
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
        throw new Error("Bad size");
    }
  },


  serializeShortString: function (b, string) {
    if (typeof(string) != "string") {
      throw new Error("param must be a string");
    }
    var byteLength = Buffer.byteLength(string, 'utf8');
    if (byteLength > 0xFF) {
      throw new Error("String too long for 'shortstr' parameter");
    }
    if (1 + byteLength + b.used >= b.length) {
      throw new Error("Not enough space in buffer for 'shortstr'");
    }
    b[b.used++] = byteLength;
    b.write(string, b.used, 'utf8');
    b.used += byteLength;
  },

  serializeLongString: function(b, string) {
    // we accept string, object, or buffer for this parameter.
    // in the case of string we serialize it to utf8.
    if (typeof(string) == 'string') {
      var byteLength = Buffer.byteLength(string, 'utf8');
      serializer.serializeInt(b, 4, byteLength);
      b.write(string, b.used, 'utf8');
      b.used += byteLength;
    } else if (typeof(string) == 'object') {
      serializer.serializeTable(b, string);
    } else {
      // data is Buffer
      var byteLength = string.length;
      serializer.serializeInt(b, 4, byteLength);
      b.write(string, b.used); // memcpy
      b.used += byteLength;
    }
  },

  serializeDate: function(b, date) {
    serializer.serializeInt(b, 8, date.valueOf() / 1000);
  },

  serializeBuffer: function(b, buffer) {
    serializer.serializeInt(b, 4, buffer.length);
    buffer.copy(b, b.used, 0);
    b.used += buffer.length;
  },

  serializeBase64: function(b, buffer) {
    serializer.serializeLongString(b, buffer.toString('base64'));
  },

  isBigInt: function(value) {
    return value > 0xffffffff;
  },

  getCode: function(dec) { 
    var hexArray = "0123456789ABCDEF".split('');
    
    var code1 = Math.floor(dec / 16);
    var code2 = dec - code1 * 16;
    return hexArray[code2];
  },

  isFloat: function(value){
    return value === +value && value !== (value|0);
  },

  serializeValue: function(b, value) {
    switch (typeof(value)) {
      case 'string':
        b[b.used++] = 'S'.charCodeAt(0);
        serializer.serializeLongString(b, value);
        break;

      case 'number':
        if (!serializer.isFloat(value)) {
          if (serializer.isBigInt(value)) {
            // 64-bit uint
            b[b.used++] = 'l'.charCodeAt(0);
            serializer.serializeInt(b, 8, value);
          } else {
            //32-bit uint
            b[b.used++] = 'I'.charCodeAt(0);
            serializer.serializeInt(b, 4, value);
          }
        } else {
          //64-bit float
          b[b.used++] = 'd'.charCodeAt(0);
          serializer.serializeFloat(b, 8, value);
        }
        break;

      case 'boolean':
        b[b.used++] = 't'.charCodeAt(0);
        b[b.used++] = value;
        break;

      default:
      if (value instanceof Date) {
        b[b.used++] = 'T'.charCodeAt(0);
        serializer.serializeDate(b, value);
      } else if (value instanceof Buffer) {
        b[b.used++] = 'x'.charCodeAt(0);
        serializer.serializeBuffer(b, value);
      } else if (Array.isArray(value)) {
        b[b.used++] = 'A'.charCodeAt(0);
        serializer.serializeArray(b, value);
      } else if (typeof(value) === 'object') {
        b[b.used++] = 'F'.charCodeAt(0);
        serializer.serializeTable(b, value);
      } else {
        this.throwError("unsupported type in amqp table: " + typeof(value));
      }
    }
  },

  serializeTable: function(b, object) {
    if (typeof(object) != "object") {
      throw new Error("param must be an object");
    }

    // Save our position so that we can go back and write the length of this table
    // at the beginning of the packet (once we know how many entries there are).
    var lengthIndex = b.used;
    b.used += 4; // sizeof long
    var startIndex = b.used;

    for (var key in object) {
      if (!object.hasOwnProperty(key)) continue;
      serializer.serializeShortString(b, key);
      serializer.serializeValue(b, object[key]);
    }

    var endIndex = b.used;
    b.used = lengthIndex;
    serializer.serializeInt(b, 4, endIndex - startIndex);
    b.used = endIndex;
  },

  serializeArray: function(b, arr) {
    // Save our position so that we can go back and write the byte length of this array
    // at the beginning of the packet (once we have serialized all elements).
    var lengthIndex = b.used;
    b.used += 4; // sizeof long
    var startIndex = b.used;

    var len = arr.length;
    for (var i = 0; i < len; i++) {
      serializer.serializeValue(b, arr[i]);
    }

    var endIndex = b.used;
    b.used = lengthIndex;
    serializer.serializeInt(b, 4, endIndex - startIndex);
    b.used = endIndex;
  },

  serializeFields: function(buffer, fields, args, strict) {
    var bitField = 0;
    var bitIndex = 0;
    for (var i = 0; i < fields.length; i++) {
      var field = fields[i];
      var domain = field.domain;
      if (!(field.name in args)) {
        if (strict) {
          throw new Error("Missing field '" + field.name + "' of type '" + domain + "' while executing AMQP method '" + 
            arguments.callee.caller.arguments[1].name + "'");
        }
        continue;
      }

      var param = args[field.name];

      //debug("domain: " + domain + " param: " + param);

      switch (domain) {
        case 'bit':
          if (typeof(param) != "boolean") {
            throw new Error("Unmatched field " + JSON.stringify(field));
          }

          if (param) bitField |= (1 << bitIndex);
          bitIndex++;

          if (!fields[i+1] || fields[i+1].domain != 'bit') {
            //debug('SET bit field ' + field.name + ' 0x' + bitField.toString(16));
            buffer[buffer.used++] = bitField;
            bitField = 0;
            bitIndex = 0;
          }
          break;

        case 'octet':
          if (typeof(param) != "number" || param > 0xFF) {
            throw new Error("Unmatched field " + JSON.stringify(field));
          }
          buffer[buffer.used++] = param;
          break;

        case 'short':
          if (typeof(param) != "number" || param > 0xFFFF) {
            throw new Error("Unmatched field " + JSON.stringify(field));
          }
          serializer.serializeInt(buffer, 2, param);
          break;

        case 'long':
          if (typeof(param) != "number" || param > 0xFFFFFFFF) {
            throw new Error("Unmatched field " + JSON.stringify(field));
          }
          serializer.serializeInt(buffer, 4, param);
          break;

        // In a previous version this shared code with 'longlong', which caused problems when passed Date 
        // integers. Nobody expects to pass a Buffer here, 53 bits is still 28 million years after 1970, we'll be fine.
        case 'timestamp':
          serializer.serializeInt(buffer, 8, param);
          break;

        case 'longlong':
          for (var j = 0; j < 8; j++) {
              buffer[buffer.used++] = param[j];
          }
          break;

        case 'shortstr':
          if (typeof(param) != "string" || param.length > 0xFF) {
            throw new Error("Unmatched field " + JSON.stringify(field));
          }
          serializer.serializeShortString(buffer, param);
          break;

        case 'longstr':
          serializer.serializeLongString(buffer, param);
          break;

        case 'table':
          if (typeof(param) != "object") {
            throw new Error("Unmatched field " + JSON.stringify(field));
          }
          serializer.serializeTable(buffer, param);
          break;

        default:
          throw new Error("Unknown domain value type " + domain);
      }
    }
  }
};