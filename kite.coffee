Kite = require 'kite-amqp'
kite =  new Kite 'bahadir'
  hello: (options, callback) ->
    callback null, 'Hello World!'

run = (key, secret) ->
  http = require 'http'
  http.get "http://localhost:3000/-/kite/login?key=#{key}&secret=#{secret}", (res) ->
    res.on 'data', (chunk) ->
      data = JSON.parse chunk.toString()
      config =
        pidPath     : "/tmp/kite.pid"
        logFile     : "/tmp/kite.log"
        amqp        :
          host      : data.host
          login     : data.username
          password  : data.password
        apiUri      : 'https://dev-api.koding.com/1.0'
       
      kite.run config

run 'bahadir', 'f69cb411841bf2168ae8bdaf'