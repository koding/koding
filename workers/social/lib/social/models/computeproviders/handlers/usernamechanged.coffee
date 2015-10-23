module.exports = usernameChanged = ({ oldUsername, username, isRegistration }) ->

  return  unless oldUsername and username
  return  if isRegistration

  JMachine = require '../machine'

  console.log "Removing user #{oldUsername} vms..."

  JMachine.update
    provider      : { $in: ['koding', 'managed'] }
    credential    : oldUsername
  ,
    $set          :
      userDeleted : yes
  ,
    multi         : yes
  , (err) ->

    if err?
      console.error \
        "Failed to mark them as deleted for #{oldUsername}:", err
