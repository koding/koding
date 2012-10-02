{exec} = require 'child_process'

error =(message)->
  {message} = message if message.message?
  return no unless message
  console.log "There was an error: "
  console.error message
  console.trace()
  yes

execute =(cmd, callback)->
  exec cmd, (err, stdout, stderr)->
    callback stdout unless error err?.message or stderr

module.exports = (vhost, config, callback)->
  execute "rabbitmqctl list_vhosts", (stdout)->
    vhosts = stdout.split('\n').slice(1,-2)
    if vhost in vhosts
      return callback new Error("Vhost exists: #{vhost}")
    else
      {login} = config.mq
      console.log "Adding vhost: #{vhost}"
      execute "rabbitmqctl add_vhost #{vhost}", (stdout)->
        console.log stdout
        execute "rabbitmqctl set_permissions -p #{vhost} #{login} \".*\" \".*\" \".*\"", (stdout)->
          console.log stdout
          callback null