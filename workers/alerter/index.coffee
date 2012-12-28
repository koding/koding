amqp = require 'amqp'
{argv} = require 'optimist'

if argv.c
  config = require argv.c 
else
  console.log "Please provide a valid config file with -c arg. Exiting."
  process.exit()

connection = amqp.createConnection config.mq
connection.on 'ready',->
  connection.exchange 'public-status',{autoDelete:no},(exchange)->
    exchange.publish 'exit','sharedhosting is dead'
    exchange.close()
    connection.end()


