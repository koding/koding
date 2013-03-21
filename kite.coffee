#this is weird, change this
KiteBase = require './node_modules/kite-amqp/lib/kite-amqp/kite.coffee'

config = 
  name      : 'cihangir'
  apiAdress : 'http://localhost:3000'
  key       : "key-01eea49d10ca9542eb9fcd75"
  secret    : "secret-b14c70d9e5f29b4e41799e85"

kite = new KiteBase config,
  hello: (options, callback) ->
    callback null, 'Hello World!'

  helloMath: (options, callback) ->
    callback null, 'Hello World! Math.random()'
