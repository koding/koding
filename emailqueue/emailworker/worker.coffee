fs        = require 'fs'
nodePath  = require 'path'
{argv}    = require 'optimist'
postmark  = require('postmark') argv.p

populateTemplate =(message, callback)->
  {event} = message.notification
  template = nodePath.join('../templates/', event)
  try
    injected = require template
  catch e
    return callback new Error "No template found for event type: #{event}"
  callback null, injected message

process.on 'message', (message)->
  console.log 'PROCESSING AN ITEM', message
  populateTemplate message, (err, injectedMessage)->
    if err
      console.log 'THERE WAS AN ERROR:', err
    else
      injectedMessage.To    = message.notification.email
      injectedMessage.From  = 'hi@koding.com'
      postmark.send injectedMessage, ->
        console.log 'RESPONSE FROM POSTMARK', arguments
        process.send 'FINISHED'

setInterval (->), 100000