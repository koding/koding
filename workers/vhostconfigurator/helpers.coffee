{exec} = require 'child_process'

exports.error = error = (message)->
  {message} = message if message.message?
  return no unless message
  console.log "There was an error: "
  console.error message
  console.trace()
  yes

exports.execute =(cmd, callback)->
  exec cmd, (err, stdout, stderr)->
    console.log 'args', arguments
    callback stdout #unless error err?.message or stderr
