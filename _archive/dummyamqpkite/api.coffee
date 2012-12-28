Kite = require 'kite-amqp'

module.exports = new Kite 'dummyamqpkite'
  
  foo:(data, callback)->
    console.log 'hello'
    callback null, 42