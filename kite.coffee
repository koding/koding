#this is weird, change this
KiteBase = require './node_modules/kite-amqp/lib/kite-amqp/kite.coffee'

config = 
  name      : 'cihangir'
  apiAdress : 'http://localhost:3000'
  key       : "kite-api-key-4714ad9071adb8fd330042b6"
  secret    : "kite-api-secret-99b593f4f85e6034fd725134"

kite = new KiteBase config,
  hello: (options, callback) ->
    callback null, 'Hello World!'

  helloMath: (options, callback) ->
    callback null, 'Hello World! Math.random()'
