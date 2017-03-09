module.exports = usernameChanged = ({ oldUsername, username, isRegistration }) ->

  return  unless oldUsername and username
  return  if isRegistration

  JUser    = require '../../user'
  JMachine = require '../machine'

  console.log "Removing user #{oldUsername} vms..."

  JMachine.update
    provider      : 'managed'
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

    # remove user from shared machines, eg. permanent or collaboration machines.
    JUser.one { username }, (err, user) ->

      return console.log 'Failed to fetch user:', err  if err or not user

      JMachine.some
        'users.username': oldUsername
        'users.owner'   : no
      , {}
      , (err, machines = []) ->

        console.log 'Failed to fetch machines:', err  if err

        machines.forEach (machine) ->
          machine.removeUsers { targets: [ user ], force: yes }, (err) ->
            console.log "Couldn't remove user from users:", err  if err
