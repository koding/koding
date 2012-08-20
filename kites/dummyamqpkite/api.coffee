Kite = require 'kite-amqp'

module.exports = new Kite 'dummyamqpkite'
  
  foo:(data, callback)-> callback null, 42