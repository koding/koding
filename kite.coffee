#this is weird, change this
KiteBase = require './node_modules/kite-amqp/lib/kite-amqp/kite.coffee'

config = 
  name      : 'cihangir'
  apiAdress : 'http://localhost:3000'
  key       : "f3671e932f984ab6180a2caed83c70c238b9f9b9e29f8e677e6b93a99b878378"

kite = new KiteBase config,
  hello: (options, callback) ->
    callback null, 'Hello World!'

  helloMath: (options, callback) ->
    callback null, 'Hello World! Math.random()'
