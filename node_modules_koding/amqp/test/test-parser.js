// Make sure we get the correct results when splitting frames across
// data packets. See https://github.com/postwait/node-amqp/issues/65
require('./harness');
var Connection = require('../amqp').Connection;
var _ = require('lodash');
var EventEmitter = require('events').EventEmitter;
_.extend(Connection.prototype, EventEmitter.prototype);

var errorThrown = false;

function fresh_connection() {
  var c = new Connection();
  EventEmitter.call(c);
  c.on('error', function() {
    errorThrown = true;
  });

  c.write = function() {};
  c.emit('connect');
  return c;
}

connection = fresh_connection();

function packets() {
  for (var i in arguments) {
    connection.emit('data', new Buffer(arguments[i]));
  }
}

// First, check that we will wait for a full header if sent only a
// partial one. For this purpose we'll use a heartbeat frame.
var heartbeat = [
  8, // 'type'
  0, 0, // channel
  0, 0, 0, 0, // frame size, exclusive of the header
  206]; // frame delimiter

packets(heartbeat.slice(0, 4), heartbeat.slice(4));

// Now make sure we can send a full method frame. We'll use
// basic.consume with default arguments.

connection = fresh_connection();

var consume = [
  1,0,1,0,0,0,13, // frame header
  0,60,0,20, // method header
  0,0,0,0,0,0,0,0,0, // content (no fields)
  206]; // frame delimiter

for (var i = 0; i < consume.length; i++) {
  connection = fresh_connection();
  packets(consume.slice(0, i), consume.slice(i));
}

// And test if a packet with more than one frame gets parsed OK

var consumeX2 = [
  1,0,1,0,0,0,13, // frame header
  0,60,0,20, // method header
  0,0,0,0,0,0,0,0,0, // content (no fields)
  206,
  1,0,1,0,0,0,13, // frame header
  0,60,0,20, // method header
  0,0,0,0,0,0,0,0,0, // content (no fields)
  206
]

for (var j = 0; j < consumeX2.length; j++) {
  connection = fresh_connection();
  packets(consumeX2.slice(0, j), consumeX2.slice(j));
}

assert(!errorThrown);
