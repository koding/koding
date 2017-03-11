remote  = require 'app/remote'
globals = require 'globals'


module.exports = (_machine, rules) ->

  machine = remote.revive _machine.toJS()

  for user in machine.users when user.id is globals.userId
    for rule in rules
      return no  unless user[rule]
    return yes

  return no
