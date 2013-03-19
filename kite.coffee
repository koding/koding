http = require 'http'
Kite = require 'kite-amqp'

kite =  new Kite 'cihangir',
  hello: (options, callback) ->
    callback null, 'Hello World!'

__createAmqpConfig = (res) ->

  config =
    amqp          :
      port        : 5672
      host        : 'web0.dev.system.aws.koding.com'
      protocol    : "amqp:"
      login       : 'guest'
      password    : 's486auEkPzvUjYfeFTMQ'
      vhost       : '/'
      heartbeat   : 10

      
  config.amqp.port      = res.port if res?.port?
  config.amqp.host      = res.host if res?.host?
  config.amqp.protocol  = "amqp:"
  config.amqp.login     = res.username if res?.username?
  config.amqp.password  = res.password if res?.password?
  config.amqp.vhost     = res.vhost if res?.vhost?
  config.amqp.heartbeat = res.heartbeat if res?.heartbeat?

  return config

__resReport = (error,result,callback)->
  if error
    callback? __wrapErr error
  else
    callback? null,result

__wrapErr = (err)->
  message : err.message
  stack   : err.stack

apiAdress = 'http://localhost:3000'
options = 
  key : "fasdfa"
  secret : "a2323"

url = "#{apiAdress}/-/kite/login?key=#{options.key}&secret=#{options.secret}"

http.get url, (res) =>
  res.on "data", (chunk) ->
    data = JSON.parse chunk.toString()
    config = __createAmqpConfig data 
    kite.run config

  res.on "error", (e) ->
    console.log "Cannot start Kite #{e.message}"