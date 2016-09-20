remote = require 'app/remote'


module.exports = (machine, revive = no) ->

  provider = if revive then machine.provider else machine.get 'provider'

  switch provider
    when 'koding', 'managed'
      return if revive then machine.credential else machine.get 'credential'
    else # Use users array for other types of providers ~ GG
      jMachine = if revive then machine else remote.revive machine.toJS()
      for user in jMachine.users when user.owner
        return user.username
