amqp = require("amqp")

connection = amqp.createConnection {host: "localhost"},{defaultExchangeName:"koding"}

# Wait for connection to become established.
connection.on "ready", ->
  
  console.dir connection
  # Create a queue and bind to all messages.
  # Use the default 'amq.topic' exchange
  connection.queue "devrim", (q) ->
    
    # Catch all messages
    q.bind "koding","kfmjs.#"
    
    # Receive messages
    q.subscribe (message,headers,deliveryInfo) ->
      
      # Print messages to stdout
      console.log arguments
      console.log message.data+''

      msg = message.data+''
      channel = deliveryInfo.routingKey

