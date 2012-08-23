Kite = require 'kite-amqp'

debugger
module.exports = new Kite 'dummyamqpkite'
  
  foo:(data, callback)->
    callback null, 42